# Video Manipulator app

## General Information

This project describes possibilities of standard gems for video processing at Ruby on Rails, plus some custom tweaks and hacks for fancy video effects.

For database in this project is used NoSQL database [MongoDB](https://www.mongodb.com/).

Videos are processed in background with [sidekiq](https://github.com/mperham/sidekiq) gem.

All video processing is happens with [FFmpeg](https://ffmpeg.org/) utility: some simple video effects and audio effects plus fancy video effects from [Frei0r](https://frei0r.dyne.org/) plugin.

For real time processing progress refresh project uses web socket nofications with rails' [Action Cable](http://edgeguides.rubyonrails.org/action_cable_overview.html).

For more details read corresponding article.

**TODO: Add article link to Yalantis website**

## Project setup up

Project depends on this software:

1. Ruby Version Manager
2. Ruby 2.3.0
3. Rails 5.0.4
3. MongoDB 3.2.10
4. Redis 3.2.5
5. FFmpeg 3.3.2
6. Frei0r FFmpeg plugin 1.6.1

## Project start up (developemnt environment)

1. Start server with `rails s` command
2. Start sidekiq with `bundle exec sidekiq -C config/sidekiq.yml` command
