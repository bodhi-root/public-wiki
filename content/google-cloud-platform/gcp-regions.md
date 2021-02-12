---
title: GCP Regions
---

GCP has data centers in the following North American regions:

| Region      | Zones      | Location                        | GCE Pricing |
|-------------|------------|---------------------------------|-------|
| us-central1 | a, b, c, f | Council Bluffs, Iowa, USA       | 48.54 |
| us-east1    | b, c, d | Moncks Corner, South Carolina, USA | 48.54 |
| us-east4    | a, b, c | Ashburn, Northern Virginia, USA    | 54.67 |
| us-west1    | a, b, c | The Dalles, Oregon, USA            | 48.54 |
| us-west2    | a, b, c | Los Angeles, California, USA       | 58.31 |
| northamerica-northeast1 | a, b, c | Montréal, Québec, Canada | 52.59 |

The last column provides the monthly price for running an n1-standard-2 GCE instance (2 CPUs, 7.5 GB RAM) without any persistent disk.  These costs take into effect the 30% sustained use discount (as shown on GCP pricing calculator).  They were retrieved on August 26, 2019.

Based on this, Iowa (us-central1) is a good choice for many U.S. companies since it is among the lowest cost providers and is not only near Cincinnati but also central with respect to many of our stores.  Virginia (us-east4) is closer to Cincinnati, but we would pay a noticeable premium for servers in that location.
