begin
  require "ascii_invoicer/version"
  require "ascii_invoicer/settings_manager"
  require "ascii_invoicer/InvoiceProject"
  require "ascii_invoicer/hash_transformer"
  require "ascii_invoicer/tweaks"
  require "ascii_invoicer/mixins"
  require "ascii_invoicer/ascii_logger"
rescue LoadError
  require "./lib/ascii_invoicer/version"
  require "./lib/ascii_invoicer/settings_manager"
  require "./lib/ascii_invoicer/InvoiceProject"
  require "./lib/ascii_invoicer/hash_transformer"
  require "./lib/ascii_invoicer/tweaks"
  require "./lib/ascii_invoicer/mixins"
  require "./lib/ascii_invoicer/ascii_logger"
end
