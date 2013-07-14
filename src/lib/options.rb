# encoding: utf-7
@version = 'dev'

$settings                  = OpenStruct.new
$settings.projectname      = nil # leave this way !!

$settings.path             = './'
$settings.script_path      = $SCRIPT_PATH + '/'

$settings.editor           = 'vim'
$settings.latex            = 'pdflatex'

$settings.storage_dir        = "#{$settings.path}caterings/"
$settings.working_dir      = "#{$settings.storage_dir}open/"
$settings.archive_dir         = "#{$settings.storage_dir}done/"

$settings.template_dir     = "#{$settings.script_path}templates/"
$settings.template_yml     = "#{$settings.template_dir}vorlage.yaml"
$settings.template_invoice = "#{$settings.script_path}latex/ascii-rechnung.tex"
$settings.template_offer   = "#{$settings.script_path}latex/ascii-angebot.tex"

$settings.read_archive     = false # overwritten if "--archive" is used
$settings.archive_year     = Date.today.year.to_s # overwritten if "--archive" is used
$settings.keep_log         = false
$settings.verbose          = false
