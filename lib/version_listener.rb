require 'rexml/document'
require 'plist'
require 'net/http'
require 'uri'
require 'json'

class VersionListener < Redmine::Hook::ViewListener

  def view_projects_show_left(context)
    @repository = context[:project].repository
    return if @repository.nil?

#    @html = ''
    entries = @repository.entries
    @file = nil
    search_file(entries, 'AndroidManifest.xml')
    if @file.present?
      platform = 'android'
    else
#      search_file(entries, 'Info.plist')
      if @file.present?
        platform = 'ios'
      else
        return
      end
    end
#    @html << 'search result: '
#    @html << @file.path 
#    @html

    content = @repository.cat(@file.path)
    return if content.nil?

    version = __send__("lookup_version_#{platform}", content)
    return if version.nil?

    html = ''
    html << platform
    html << ' Release version: '
    html << version
    html
  end

  def lookup_version_android(content)
    doc = REXML::Document.new(content)
    package = doc.elements['manifest'].attributes['package']
    json = get_json('http://androidquery.appspot.com/api/market?app=' + package)
    json['version']
  end

  def lookup_version_ios(content)
    result = Plist::parse_xml(content)
    bundleId = result['CFBundleIdentifier']
    json = get_json('http://itunes.apple.com/lookup?bundleId=' + bundleId)
    json['result'][0]['version']
  end

  def search_file(entries, name)
    entries.each do |entry|
#      @html << entry.name
#      @html << '<br>'
      return @file = entry if entry.name == name
      if entry.is_dir?
        search_file(@repository.entries(entry.path), name)
#        return @file if @file.present?
      end
    end
  end

  def get_json(url)
    JSON.parse(Net::HTTP.get(URI.parse(url)))
  end

end
