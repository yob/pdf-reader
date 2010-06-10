# coding: utf-8


class PDF::Reader
  class Page
    def initialize(ohash, page_dict)
      @ohash, @page_dict = ohash, page_dict
    end

    def ohash
      @ohash
    end

    def page_dict
      @page_dict
    end

    def content_streams
      return [] if page_dict[:Contents].nil?

      if ohash.object(page_dict[:Contents]).kind_of?(Array)
        contents = @ohash.object(page_dict[:Contents])
      else
        contents = [page_dict[:Contents]]
      end
      contents.map { |content| @ohash.object(content) }
      #content_stream(direct_contents, fonts)
    end

    def fonts
      return {} if resources[:Font].nil?

      fonts = {}
      ohash.object(resources[:Font]).each do |label, desc|
        desc = @ohash.object(desc)
        fonts[label] = PDF::Reader::Font.new
        fonts[label].label = label
        fonts[label].subtype = desc[:Subtype] if desc[:Subtype]
        fonts[label].basefont = desc[:BaseFont] if desc[:BaseFont]
        fonts[label].encoding = PDF::Reader::Encoding.new(@ohash.object(desc[:Encoding]))
        fonts[label].descendantfonts = desc[:DescendantFonts] if desc[:DescendantFonts]
        if desc[:ToUnicode]
          # this stream is a cmap
          stream = desc[:ToUnicode]
          fonts[label].tounicode = PDF::Reader::CMap.new(stream.unfiltered_data)
        end
      end
      fonts
    end

    def parent(dict)
      if dict.nil? || dict[:Parent].nil?
        return []
      else
        return parent(ohash.object(dict[:Parent])) + [ohash.object(dict[:Parent])]
      end
    end

    def parents
      @parents ||= parent(page_dict)
    end

    def resources
      resources = {}
      parents.reverse.each do |parent|
        resources.merge!(ohash.object(parent[:Resources])) if ohash.object(parent[:Resources])
      end
      resources.merge!(ohash.object(page_dict[:Resources])) if ohash.object(page_dict[:Resources])
      resolve_references(resources)
    end
    ################################################################################
    # Convert any PDF::Reader::Resource objects into a real object
    def resolve_references(obj)
      case obj
      when PDF::Reader::Stream then
        obj.hash = resolve_references(obj.hash)
        obj
      when PDF::Reader::Reference then
        resolve_references(@ohash.object(obj))
      when Hash                   then obj.each { |key,val| obj[key] = resolve_references(val) }
      when Array                  then obj.collect { |item| resolve_references(item) }
      else
        obj
      end
    end
  end
end
