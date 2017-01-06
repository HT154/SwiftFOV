# SwiftFOV
A Swift port of libfov (https://code.google.com/archive/p/libfov/)

I wanted to use libfov from Swift, but dealing with function pointers was a mess.

This is an almost-verbatim reimplementation of fov.c, excluding the corner peek and shape options (only circle is imlpemented).

Notably, fov.c makes use of C macros to define its functions. FOV.swift trades those for closures and a slight performance hit to maintain the same conciseness.
