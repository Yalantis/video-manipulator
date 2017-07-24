# Video Manipulator app

## General Information

This project describes possibilities of standard gems for video processing at Ruby on Rails, plus some custom tweaks and hacks for fancy video effects.

For database in this project is used NoSQL database [MongoDB](https://www.mongodb.com/).

Videos are processed in background with [sidekiq](https://github.com/mperham/sidekiq) gem.

All video processing is happens with [FFmpeg](https://ffmpeg.org/) utility: some simple video effects and audio effects plus fancy video effects from [Frei0r](https://frei0r.dyne.org/) plugin.

For real time processing progress refresh project uses web socket nofications with rails' [Action Cable](http://edgeguides.rubyonrails.org/action_cable_overview.html).

For more details read corresponding article.

**TODO: Add article link to Yalantis website**

Project Setup
-------------

**1. Install FFmpeg with all options**

If your operating system is OSX than you could use homebrew for installation

```
brew install ffmpeg --with-fdk-aac --with-frei0r --with-libvo-aacenc --with-libvorbis --with-libvpx --with-opencore-amr --with-openjpeg --with-opus --with-schroedinger --with-theora --with-tools
```

Maybe not all of these options are needed for current project but I included almost all possible to avoid issues when something is not working if some extension has not been installed.

On other Linux OS like Ubuntu or Debian it might require to install ffmpeg from sources. Maybe this guide could be helpful [https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu](https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu)

**2. Fix frei0r**

When I installed ffmpeg with Frei0r, it's effects were not working. To check if you have such issue run ffmpeg with frei0r effects:

`ffmpeg -v debug -i 1.mp4 -vf frei0r=glow:0.5 output.mpg`

you might see something like this:

```
[Parsed_frei0r_0 @ 0x7fe7834196a0] Looking for frei0r effect in '/Users/user/.frei0r-1/lib/glow.dylib' [Parsed_frei0r_0 @ 0x7fe7834196a0] Looking for frei0r effect in '/usr/local/lib/frei0r-1/glow.dylib' [Parsed_frei0r_0 @ 0x7fe7834196a0] Looking for frei0r effect in '/usr/lib/frei0r-1/glow.dylib'
```

FFmpeg is probably right. If you will ls -l /usr/local/lib/frei0r-1/ you will see that plug-ins are installed with .so extension.

On my machine (OSX 10.12.5, ffmpeg 3.3.2, frei0r-1.6.1), I just did something like this:

`for file in /usr/local/lib/frei0r-1/*.so ; do cp $file "${file%.*}.dylib" ; done`

Also I had to set this environment variable with path to folder where these .dylib files are stored:

`export FREI0R_PATH=/usr/local/Cellar/frei0r/1.6.1/lib/frei0r-1`

This solution looks like some strange hack, but finally after all this operations I have got Frei0r working well.

**2. Install ffmpeg thumbnailer**

`brew install ffmpegthumbnailer` this utility would be used for video thumbnail creation.

**3. Install imagemagick**

`brew install imagemagick` also project would generate many thumbnails and these thumbnails would require to be processed and stored.

**4. Install MongoDB, Redis**

`brew install mongodb` project's database

`brew install redis` storage for sidekiq job parameters and data

**5. Ruby and Rails**

I assume that you already have rvm (ruby version manager), ruby and rails installed so I am not going to cover this here.

This project uses `ruby 2.3.0` and `Rails 5.0.1`


Project start up (developemnt environment)
------------------------------------------

1. Start server with `rails s` command
2. Start sidekiq with `bundle exec sidekiq -C config/sidekiq.yml` command
