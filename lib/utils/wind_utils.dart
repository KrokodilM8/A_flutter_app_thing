/// Converts wind direction in degrees to a cardinal string.
String getWindDirection(int? deg) {
  if (deg == null) return '-';
  const directions = [
    'North',
    'North / North-East',
    'North-East',
    'East / North-East',
    'East',
    'East / South-East',
    'South-East',
    'South / South-East',
    'South',
    'South / South-West',
    'South-West',
    'West / South-West',
    'West',
    'West / North-West',
    'North-West',
    'North / North-West',
  ];
  return directions[((deg + 11.25) ~/ 22.5) % 16];
}
