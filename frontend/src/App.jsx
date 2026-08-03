import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ProtectedRoute } from './components/ProtectedRoute';
import { AuthLayout } from './layouts/AuthLayout';
import { DashboardLayout } from './layouts/DashboardLayout';
import { Login } from './pages/auth/Login';
import { ForgotPassword } from './pages/auth/ForgotPassword';
import { Landing } from './pages/public/Landing';

// Import All Generated Dashboards & Pages
import { ChildProfile } from './pages/dashboard/ChildProfile';
import { GrowthDashboard } from './pages/dashboard/GrowthDashboard';
import { VaccineTracker } from './pages/dashboard/VaccineTracker';
import { GlobalVaccineTracker } from './pages/dashboard/GlobalVaccineTracker';
import { BookingFlow } from './pages/dashboard/BookingFlow';
import { TeleconsultSession } from './pages/dashboard/TeleconsultSession';
import { Chatbot } from './pages/dashboard/Chatbot';
import { AdminDashboard } from './pages/admin/AdminDashboard';
import { ManageUsers } from './pages/admin/ManageUsers';
import { AdminDoctors } from './pages/admin/AdminDoctors';
import { AdminFacilities } from './pages/admin/AdminFacilities';
import { PaymentHistory } from './pages/admin/PaymentHistory';
import ContactMessages from './pages/admin/ContactMessages';
import { MainDashboard } from './pages/dashboard/MainDashboard';
import { FacilityDoctors } from './pages/facility/FacilityDoctors';
import { FacilityDashboard } from './pages/facility/FacilityDashboard';
import { 
  PatientListPlaceholder
} from './pages/dashboard/Placeholders';
import { TeleconsultHub } from './pages/dashboard/TeleconsultHub';
import { EmergencyGuidance } from './pages/dashboard/EmergencyGuidance';
import { HealthEducation } from './pages/dashboard/HealthEducation';
import { ArticleDetail } from './pages/dashboard/ArticleDetail';
import { MyChildren } from './pages/dashboard/MyChildren';
import { DoctorSchedule } from './pages/doctor/DoctorSchedule';
import { PatientRecords } from './pages/doctor/PatientRecords';
import { DoctorInbox } from './pages/dashboard/DoctorInbox';
import useAuthStore from './store/authStore';

// Conditional Router for Appointment overlap
const AppointmentRouter = () => {
    const userRole = useAuthStore(state => state.user?.role);
    return userRole === 'DOCTOR' ? <DoctorSchedule /> : <BookingFlow />;
};

/* ============================================================
   APP ROUTER
   ============================================================ */
function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Landing />} />
        
        {/* Auth Zone */}
        <Route element={<AuthLayout />}>
          <Route path="/login" element={<Login />} />
          <Route path="/forgot-password" element={<ForgotPassword />} />
          <Route path="/register" element={<Navigate to="/login" />} />
        </Route>
        
        {/* Secure Dashboard Core */}
        <Route element={<ProtectedRoute allowedRoles={['PARENT', 'DOCTOR', 'FACILITY', 'ADMIN']} />}>
          <Route element={<DashboardLayout />}>
             <Route path="/dashboard" element={<MainDashboard />} />
             <Route path="/child/my-children" element={<MyChildren />} />
             <Route path="/child/:id" element={<ChildProfile />} />
             <Route path="/child/:id/growth" element={<GrowthDashboard />} />
             <Route path="/child/:id/vaccines" element={<VaccineTracker />} />
             <Route path="/vaccines" element={<GlobalVaccineTracker />} />
             <Route path="/appointments" element={<AppointmentRouter />} />
             <Route path="/teleconsult" element={<TeleconsultHub />} />
             <Route path="/teleconsult/:appointmentId" element={<TeleconsultSession />} />
             <Route path="/chatbot" element={<Chatbot />} />
             <Route path="/admin" element={<AdminDashboard />} />
             <Route path="/admin/users" element={<ManageUsers />} />
             <Route path="/admin/doctors" element={<AdminDoctors />} />
             <Route path="/admin/facilities" element={<AdminFacilities />} />
             <Route path="/admin/payments" element={<PaymentHistory />} />
             <Route path="/admin/messages" element={<ContactMessages />} />
             <Route path="/education" element={<HealthEducation />} />
             <Route path="/education/:id" element={<ArticleDetail />} />
             <Route path="/emergency" element={<EmergencyGuidance />} />
             <Route path="/patients" element={<PatientRecords />} />
             <Route path="/messages" element={<DoctorInbox />} />
             <Route path="/facility/doctors" element={<FacilityDoctors />} />
             <Route path="/facility/admin" element={<FacilityDashboard />} />
          </Route>
        </Route>
        
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
