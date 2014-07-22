
# begin
  # # backward compatibility
  # require 'omf_common/lobject'
  # OMF::Common::Loggable.init_log 'labwiki', :searchPath => File.join(File.dirname(__FILE__), 'labwiki')
# rescue Exception
# end

module LabWiki
  class LWException < Exception
  end

end
