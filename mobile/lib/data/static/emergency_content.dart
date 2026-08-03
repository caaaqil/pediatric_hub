// Ported from frontend/src/pages/dashboard/EmergencyGuidance.jsx.
//
// Like the education page, the web keeps this content in the component rather
// than in the `EmergencyContact` table, so the same data lives here to keep the
// two clients identical. Rows an administrator adds through `POST /emergency`
// are shown in addition to these.

class EmergencyProtocol {
  const EmergencyProtocol({
    required this.step,
    required this.title,
    required this.somali,
    required this.body,
  });

  final int step;
  final String title;

  /// The Somali one-liner shown under the English title.
  final String somali;
  final String body;
}

class EmergencyFacility {
  const EmergencyFacility({
    required this.name,
    required this.address,
    required this.phone,
    required this.type,
    required this.open,
    required this.distance,
  });

  final String name;
  final String address;
  final String phone;
  final String type;
  final String open;
  final String distance;
}

class EmergencyNumber {
  const EmergencyNumber({required this.label, required this.number});

  final String label;
  final String number;
}

const List<EmergencyProtocol> kEmergencyProtocols = <EmergencyProtocol>[
  EmergencyProtocol(
    step: 1,
    title: 'Severe Difficulty Breathing',
    somali: 'Neefsasho dhibaato xun',
    body:
        'Look for blue lips, rapid chest retractions, or gasping. Keep the '
        'child calm in an upright position and call emergency services '
        'immediately.',
  ),
  EmergencyProtocol(
    step: 2,
    title: 'Unresponsiveness or Seizures',
    somali: 'Daran / wareeg',
    body:
        'Roll the child onto their side to keep the airway clear. Do not put '
        'anything in their mouth or hold them down. Time the seizure and call '
        'for help.',
  ),
  EmergencyProtocol(
    step: 3,
    title: 'High Fever in Infants Under 3 Months',
    somali: 'Xummad carruurta yar yar',
    body:
        'Any temperature over 38°C (100.4°F) in a baby under 3 months is a '
        'medical emergency. Go to the nearest hospital immediately — do not '
        'wait.',
  ),
  EmergencyProtocol(
    step: 4,
    title: 'Severe Dehydration',
    somali: "Biyo la'aanta xun",
    body:
        'Signs: dry mouth, no tears, sunken eyes, no urination for 8+ hours. '
        'Give ORS if conscious and transport to clinic urgently.',
  ),
  EmergencyProtocol(
    step: 5,
    title: 'Choking or Airway Blockage',
    somali: 'Wax ku xidaya neefsashada',
    body:
        'For infants: 5 back blows + 5 chest thrusts. For children: Heimlich '
        'maneuver. Call 252-1 immediately if the child cannot breathe.',
  ),
];

const List<EmergencyFacility> kEmergencyFacilities = <EmergencyFacility>[
  EmergencyFacility(
    name: 'Banadir Health Center',
    address: 'Banadir District, Mogadishu',
    phone: '+252-1',
    type: 'Health Center',
    open: '24/7',
    distance: '2.1 km',
  ),
  EmergencyFacility(
    name: 'Mogadishu General Hospital',
    address: 'Via Makka Al Mukarama, Mogadishu',
    phone: '+252-612-000001',
    type: 'Hospital',
    open: '24/7',
    distance: '3.4 km',
  ),
  EmergencyFacility(
    name: 'Kalkaal Hospital',
    address: 'KM4 Road, Mogadishu',
    phone: '+252-615-000002',
    type: 'Hospital',
    open: '24/7',
    distance: '5.2 km',
  ),
  EmergencyFacility(
    name: 'Deynile Health Center',
    address: 'Deynile District, Mogadishu',
    phone: '+252-611-111111',
    type: 'Health Center',
    open: '8am-10pm',
    distance: '7.8 km',
  ),
];

const List<EmergencyNumber> kEmergencyNumbers = <EmergencyNumber>[
  EmergencyNumber(label: 'Ambulance', number: '252-1'),
  EmergencyNumber(label: 'Police Emergency', number: '999'),
  EmergencyNumber(label: 'Banadir Hospital', number: '+252-61-0000'),
];
