module EncodingConstants
  PROCESSED_DEFAULTS = {
    resolution:           '500x400',
    video_codec:          'libx264',
    constant_rate_factor: '30',
    frame_rate:           '25',
    audio_codec:          'aac',
    audio_bitrate:        '64k',
    audio_sample_rate:    '44100',
    audio_channels:       '1',
    progress: :processing_progress
  }.freeze

  VIDEO_EFFECTS = {
    sepia:
      %w[
        -filter_complex colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131
        -c:a
        copy
      ],
    black_and_white: %w[-vf hue=s=0 -c:a copy],
    vertigo: %w[-vf frei0r=vertigo:0.2 -c:a copy],
    vignette: %w[-vf frei0r=vignette -c:a copy],
    sobel: %w[-vf frei0r=sobel -c:a copy],
    pixelizor: %w[-vf frei0r=pixeliz0r -c:a copy],
    invertor: %w[-vf frei0r=invert0r -c:a copy],
    rgbnoise: %w[-vf frei0r=rgbnoise:0.2 -c:a copy],
    distorter: %w[-vf frei0r=distort0r:0.05|0.0000001 -c:a copy],
    iirblur: %w[-vf frei0r=iirblur -c:a copy],
    nervous: %w[-vf frei0r=nervous -c:a copy],
    glow: %w[-vf frei0r=glow:1 -c:a copy],
    reverse: %w[-vf reverse -af areverse],
    slow_down: %w[-filter:v setpts=2.0*PTS -filter:a atempo=0.5],
    speed_up: %w[-filter:v setpts=0.5*PTS -filter:a atempo=2.0]
  }.freeze

  AUDIO_EFFECTS = {
    echo: %w[-map 0 -c:v copy -af aecho=0.8:0.9:1000|500:0.7|0.5],
    tremolo: %w[-map 0 -c:v copy -af tremolo=f=10.0:d=0.7],
    vibrato: %w[-map 0 -c:v copy -af vibrato=f=7.0:d=0.5],
    chorus: %w[-map 0 -c:v copy -af chorus=0.5:0.9:50|60|40:0.4|0.32|0.3:0.25|0.4|0.3:2|2.3|1.3]
  }.freeze

  EFFECT_PARAMS = VIDEO_EFFECTS.merge(AUDIO_EFFECTS).freeze

  ALLOWED_EFFECTS = EFFECT_PARAMS.keys.map(&:to_s).freeze

  OBLIGATORY_STEPS = %w[normalize read_video_metadata].freeze
end
