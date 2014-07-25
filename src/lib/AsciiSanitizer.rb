# encoding: utf-8

class AsciiSanitizer
  REPLACE_HASH = {
    ?“ => '"', ?” => '"', ?‘ => "'", ?’ => "'", ?„ => '"',

    ?» => ">>", ?«  => "<<",
    ?ä => "ae", ?ö  => "oe", ?ü   => "ue",
    ?Ä => "Ae", ?Ö  => "Oe", ?Ü   => "Ue",
    ?ß => "ss", ?ï  => "i",  ?ë   => "e",
    ?æ => "ae", ?Æ  => "AE", ?œ   => "oe",
    ?Œ => "OE",
    ?€ => "EUR", ?¥ => "YEN",
    ?½ => "1/2", ?¼ => "1/4", ?¾  => "3/4",
    ?© => "(c)", ?™ => "(TM)", ?® => "(r)",
    ?♥ => "<3",  ?☺ => ":)"
  }

  def self.process(string)
    string = deumlautify string
    #string = Ascii.process string
    return string
  end

  # TODO somebody find my a gem that works and I'll replace this
  def self.deumlautify(string)
    REPLACE_HASH.each{|k,v| string = string.gsub k, v }
    string.each_char.to_a.keep_if {|c| c.ascii_only?}
    return string
  end

  def self.clean_path(path)
    path = path.strip()
    path = deumlautify path
    path.sub!(/^\./,'') # removes hidden_file_dot '.' from the begging
    path.gsub!(/\//,'_') 
    path.gsub!(/\//,'_') 
    return path
  end

end
