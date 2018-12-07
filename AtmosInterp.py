# -*- coding: utf-8 -*-
"""
Atmospheric Interpolator

This is designed to give basic atmospheric interpolation and extrapolation.
Assumptions:
    Logrithmic Pressure scale
    Constant Lapse rate between layers and above/below the top/bottom of the data
    Geopotential height is simplified to g*dz = g*(z-0) = g*z (where 0 = surface height)
    Wind and humidity above/below the top or bottom of the data are the same value as the top/bottom data.
        (So for example if you need Relh at 50 mb and the top of the data is 100 mb and Relh at 100 mb = 10% 
        then Relh at 50 mb will also be 10%.)

For a complete reference refer to Goddard 1993 (Unified Model Technical Note)
"""

