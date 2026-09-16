project('vtfv', ['c', 'cpp', 'vala'],
          version: '0.1.0',
    meson_version: '>= 1.0.0',
  default_options: ['warning_level=2', 'werror=false'],
)

i18n = import('i18n')
gnome = import('gnome')
cmake = import('cmake')

valac = meson.get_compiler('vala')

srcdir = meson.project_source_root() / 'src'
vapidir = meson.project_source_root() / 'vapi'
vtf_vapi = files('vapi/vtf.vapi')

config_h = configuration_data()
config_h.set_quoted('PACKAGE_VERSION', meson.project_version())
config_h.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_h.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
configure_file(output: 'config.h', configuration: config_h)

config_dep = valac.find_library('config', dirs: srcdir)
config_inc = include_directories('.')

add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')

vtflib_opts = cmake.subproject_options()
vtflib_opts.add_cmake_defines({
  'CMAKE_POSITION_INDEPENDENT_CODE': 'ON',
  'USE_LIBTXC_DXTN': 'OFF',
  'BUILD_SHARED_LIBS': 'OFF',
})

vtflib_proj = cmake.subproject('VTFLib', options: vtflib_opts)

# Build VTFLib
vtflib_opts = cmake.subproject_options()
vtflib_opts.add_cmake_defines({
  'CMAKE_POSITION_INDEPENDENT_CODE': 'ON',
})

vtflib_proj = cmake.subproject('VTFLib', options: vtflib_opts)

vtflib_cmake_dep = vtflib_proj.dependency('VTFLib13')

# Wrap it so we also make sure the headers are visible.
vtflib_dep = declare_dependency(
  dependencies: vtflib_cmake_dep,
  include_directories: include_directories(
    'subprojects/VTFLib',
    'subprojects/VTFLib/src',
  ),
)

subdir('data')
subdir('src')
subdir('po')

gnome.post_install(
     glib_compile_schemas: true,
    gtk_update_icon_cache: true,
  update_desktop_database: true,
)

install_subdir('subprojects/VTFLib/src',
  install_dir: get_option('libdir'),
  strip_directory: true,
)