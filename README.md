# extract

This repository contains the Deathmatch source code for my old Roblox FPS, [Extract](https://www.roblox.com/games/2014786490/Extract-alpha).
It is a project I worked on for a few months but began to abandon in favor of a new FPS.

This code is for educational purposes only. Do not expect to be able to build a game off of it. Additionally, I did not write this code with the
intention of releasing it in the future. This code is arguably poor. It was written to get the job done, as I was the only person working on it.

## Structure

The root file `M16A4.lua` is the config module for the M16A4. Among it is how all other weapons are configured internally.

### Client

Everything that is handled by the client is in this directory. This includes user interface, weapon logic, deployment, respawning, and more.

### Server

All central communication is handled by the server. This includes scorekeeping, chat relaying, hit verification, and more.

### Shared

Code that is shared between the client and server and may be used by both.

#### An extra note

All of the chat source files are excluded as I still use them in my projects to this day.

## Contributing

I have no plans of updating this project, but feel free to fork it and use it as you like.