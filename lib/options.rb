# encoding: utf-8

@options                  = OpenStruct.new
@options.test             = false
@options.path             = './'
@options.editor           = 'vim'
@options.latex            = 'pdflatex'
@options.working_dir      = "#{@options.path}projects/"
@options.template_dir     = "#{@options.path}templates/"
@options.template_yml     = "#{@options.template_dir}vorlage.yaml"
@options.template_invoice = "#{@options.template_dir}latex/ascii-rechnung.tex"
@options.template_offer   = "#{@options.template_dir}latex/ascii-angebot.tex"
@options.keep_log         = false



# future use
@options.language = 'DE'
