# constellation-contact-plan
Snippets to generate ISL contact plans in Walker-Delta constellations.

### Walker Delta Constellations:

WD constellations are usually named using the nomenclature i: t/p/f, where:

* i is the inclination;
* t is the total number of satellites;
* p is the number of equally spaced planes; and
* f is the relative spacing between satellites in adjacent planes. The change in true anomaly (in degrees) for equivalent satellites in neighbouring planes is equal to f × 360 / t.

### Satellite naming convention:

Satellites are populated in order according to WD parameters. Each satellite is named as PX_SY, where X is the plane number and Y is the satellite number within that plane. Satellites are named in order, so, for example:

* P1_S1 is the first satellite in the first plane.
* P5_S2 is the fifth satellite from the second plane.
* P1_S2 is the second satellite in the first plane, adjacent to P1_S1.
* If there are 8 satellites per plane, then P1_S8 is adjacent to P1_S1.
* The same logic applies to planes: P(X-1)_SY is "to the left" of PX_SY, and P(X+1)_SY is "to the right" of PX_SY. 
* If there are 8 planes, then P8_S4 is next to P1_S4.

### Outputs:

Files are saved in JSON format named using the following convention:

> data\_type\_a\_{semi major axis in km}\_i\_{inclination in degrees}\_t\_{total number of satellites}\_p\_{number of planes}\_f\_{relative spacing in degrees}.JSON

**Contact plans have the following format:**

All time instants are informed in seconds, relative to the scenario start date.

```JSON
{
  "PX_SY": {
    "PX_S(Y+1)": [[
      start_contact_seconds_1,
      end_contact_seconds_1
    ],
    "PX_S(Y+2)": [
      start_contact_seconds_1,
      end_contact_seconds_1
    ],[
      start_contact_seconds_2,
      end_contact_seconds_2
    ],[
      start_contact_seconds_3,
      end_contact_seconds_3
    ]]
  }
}
```

For example, in a scenario that spans 14400 seconds:

```JSON
{
  "P1_S1": {
    "P1_S2": [
      0,
      14400
    ],
    "P1_S3": [
      0,
      0
    ],
    "P1_S4": [[
      1324.511,
      3222.663
    ],[
      5000.122,
      5543.333
    ]]  
  }
}
```

P1_S1 has permanent contact with P1_S2, no contact with P1_S3, and two access intervals to P1_S4: 1324.511 [s] to 3222.663 [s] and 5000.122 [s] to 5543.333 [s].

**The scenario data is informed as a JSON like this example:**

```JSON
{
  "start_date": "1 Jan 2025 16:00:00.000",
  "end_date": "1 Jan 2025 20:00:00.000",
  "anom_type": "true",
  "graz_alt_km": 100,
  "propagator": "keplerian",
  "step_seconds": 60
}
```

where start and end date determine the scenario timespan, anom_type is the type of anomaly informed in the satellites' elements (either true or mean), propagator is the type of propagator used, and step\_seconds is the time step for the propagator used, although interpolation techniques are used to find precise access intervals i.e. precision is in the order of ms.

Satellite elements are informed as a list in the following format:

```JSON
[
  {
    "sat_id": "P1_S1",
    "sem_maj_axis_km": 7700,
    "ecc": 0,
    "inc": 75,
    "RAAN": 0,
    "arg_per": 0,
    "anom": 0
  }
]
```

Non-specified dimension are in degrees. 
