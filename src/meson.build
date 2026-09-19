
vtfv_sources = files(
  'main.vala',
  'application.vala',
  'window.vala',
  'VTFTexture.vala',
  'NearestPicture.vala'
)

vtfv_sources += vtf_vapi

vtfv_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
  vtflib_dep,
]

# Custom target for Blueprint files
blueprints = custom_target('blueprints',
  input: files(
    'gtk/window.blp'
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

vtfv_sources += gnome.compile_resources('vtfv-resources',
  'vtfv.gresource.xml',
  c_name: 'vtfv',
   dependencies: blueprints
)

executable('vtfv', vtfv_sources,
  dependencies: vtfv_deps,
  include_directories: config_inc,
  vala_args: ['--vapidir', vapidir],
  link_args: ['-lstdc++'],
  install: true,
)