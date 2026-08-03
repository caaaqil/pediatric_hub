const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const DAY_MS = 24 * 60 * 60 * 1000;

const runVaccineChecks = async () => {
    console.log('[CRON] Running daily vaccine checks...');
    const now = new Date();
    const in7Days = new Date(now.getTime() + 7 * DAY_MS);
    const in1Day  = new Date(now.getTime() + 1 * DAY_MS);

    try {
        // 1. Mark overdue vaccines as MISSED (grace period: more than 7 days past scheduled date)
        const missed = await prisma.vaccination.updateMany({
            where: {
                status: { in: ['UPCOMING', 'DUE'] },
                scheduledDate: { lt: new Date(now.getTime() - 7 * DAY_MS) },
            },
            data: { status: 'MISSED' },
        });

        // 2. Mark vaccines due within 7 days as DUE
        await prisma.vaccination.updateMany({
            where: {
                status: 'UPCOMING',
                scheduledDate: { gte: now, lte: in7Days },
            },
            data: { status: 'DUE' },
        });

        // 3. Notify parents: vaccine due in 7 days
        const due7 = await prisma.vaccination.findMany({
            where: {
                status: { in: ['UPCOMING', 'DUE'] },
                scheduledDate: {
                    gte: new Date(in7Days.getTime() - DAY_MS / 2),
                    lte: new Date(in7Days.getTime() + DAY_MS / 2),
                },
            },
            include: {
                child: {
                    include: {
                        parent: { include: { user: true } },
                    },
                },
            },
        });

        // 4. Notify parents: vaccine due in 1 day
        const due1 = await prisma.vaccination.findMany({
            where: {
                status: { in: ['UPCOMING', 'DUE'] },
                scheduledDate: {
                    gte: new Date(in1Day.getTime() - DAY_MS / 2),
                    lte: new Date(in1Day.getTime() + DAY_MS / 2),
                },
            },
            include: {
                child: {
                    include: {
                        parent: { include: { user: true } },
                    },
                },
            },
        });

        // 5. Notify parents of missed vaccines
        const missedVaccines = await prisma.vaccination.findMany({
            where: {
                status: 'MISSED',
                updatedAt: { gte: new Date(now.getTime() - DAY_MS) },
            },
            include: {
                child: {
                    include: {
                        parent: { include: { user: true } },
                    },
                },
            },
        });

        const notifications = [];

        for (const v of due7) {
            const userId = v.child?.parent?.user?.id;
            if (!userId) continue;
            notifications.push({
                userId,
                title: `Vaccine Due in 7 Days — ${v.child.firstName}`,
                body: `${v.vaccineName} (Dose ${v.doseNumber}) for ${v.child.firstName} is scheduled on ${new Date(v.scheduledDate).toLocaleDateString()}. Please visit your clinic.`,
                type: 'VACCINE',
                isRead: false,
            });
        }

        for (const v of due1) {
            const userId = v.child?.parent?.user?.id;
            if (!userId) continue;
            notifications.push({
                userId,
                title: `Vaccine Tomorrow — ${v.child.firstName}`,
                body: `Reminder: ${v.vaccineName} (Dose ${v.doseNumber}) for ${v.child.firstName} is scheduled tomorrow. Don't miss it!`,
                type: 'VACCINE',
                isRead: false,
            });
        }

        for (const v of missedVaccines) {
            const userId = v.child?.parent?.user?.id;
            if (!userId) continue;
            notifications.push({
                userId,
                title: `Missed Vaccine — ${v.child.firstName}`,
                body: `${v.vaccineName} (Dose ${v.doseNumber}) for ${v.child.firstName} was missed. Please contact your doctor to reschedule.`,
                type: 'VACCINE',
                isRead: false,
            });
        }

        if (notifications.length > 0) {
            await prisma.notification.createMany({ data: notifications });
        }

        console.log(`[CRON] Missed: ${missed.count}, Notifications sent: ${notifications.length}`);
    } catch (err) {
        console.error('[CRON] Error:', err.message);
    }
};

const startCron = () => {
    setInterval(runVaccineChecks, DAY_MS);
    runVaccineChecks(); // run immediately on startup
    console.log('[CRON] Vaccine check engine started.');
};

module.exports = { startCron, runVaccineChecks };
