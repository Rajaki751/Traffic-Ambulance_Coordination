"""Kathmandu Valley geographic defaults and landmarks for Nepal-focused routing."""

# Kathmandu Valley center (Durbar Marg area)
DEFAULT_LATITUDE = 27.7172
DEFAULT_LONGITUDE = 85.3240

# Kathmandu Valley bounding box for map fitting
VALLEY_BOUNDS = {
    "south": 27.62,
    "north": 27.78,
    "west": 85.24,
    "east": 85.45,
}

# Major Kathmandu hospitals for map reference
KATHMANDU_HOSPITALS = [
    {
        "name": "Tribhuvan University Teaching Hospital",
        "lat": 27.6815,
        "lon": 85.3240,
    },
    {
        "name": "Grande International Hospital",
        "lat": 27.7408,
        "lon": 85.3355,
    },
    {
        "name": "Nepal Mediciti Hospital",
        "lat": 27.6678,
        "lon": 85.3193,
    },
    {
        "name": "Bir Hospital",
        "lat": 27.7075,
        "lon": 85.3145,
    },
    {
        "name": "Patan Hospital",
        "lat": 27.6687,
        "lon": 85.3208,
    },
    {
        "name": "Om Hospital",
        "lat": 27.6912,
        "lon": 85.3421,
    },
]

# Key traffic junctions officers may clear
KATHMANDU_JUNCTIONS = [
    {"name": "Kalanki Chowk", "lat": 27.6943, "lon": 85.2812},
    {"name": "Koteshwor Chowk", "lat": 27.6789, "lon": 85.3487},
    {"name": "Thapathali Junction", "lat": 27.6921, "lon": 85.3198},
    {"name": "New Baneshwor", "lat": 27.6915, "lon": 85.3420},
    {"name": "Chabahil Chowk", "lat": 27.7215, "lon": 85.3462},
    {"name": "Balaju Chowk", "lat": 27.7341, "lon": 85.3055},
]
