require 'kramdown'
require 'redcarpet'
require 'pygments'

class MyRender < Redcarpet::Render::Safe
  def block_code(code, language)
    if language then
      Pygments.highlight(code, lexer: language)
    else
      "<pre class='default'><code>#{html_escape(code)}</code></pre>"
    end
  end
end

class ArticlesController < ApplicationController

  def index
    @articles = Array.new
    @categories = Hash.new
    Pathname.glob('../blogs/*') do |path|

      fn = path.basename.to_s
      fn =~ /^((\d{6})-([^.]+))\.(\w+)$/
      article = { id: $1, month: $2, name: $3, type: $4 }

      path.open("r") do |f|
        htype, head, body = parse_file(f)
        if htype == :yaml then
          article[:attr] = parse_yaml(head)
        elsif htype == :free then
          article[:attr] = parse_free(head)
        else
          next
        end

        count = @categories[article[:attr]['category']]
        if count == nil
          @categories[article[:attr]['category']] = 1;
        else
          @categories[article[:attr]['category']] = count + 1
        end

        if article[:attr]['time']
          article[:timestamp] = article[:attr]['time']
        else
          est_time = article[:month].gsub(/^(....)(..)$/, '\1-\2-01 18:00 +0800')
          article[:timestamp] = Time.parse(est_time)
        end

        filter_out = false
        if params.has_key?(:cat)
          if article[:attr]['category'] != params[:cat]
            filter_out = true
          end
          @tips = "Filtered by category: #{params[:cat]}"
        end
        if params.has_key?(:year)
          if article[:timestamp].year.to_s != params[:year]
            filter_out = true
          end
          @tips = "Filtered by year: #{params[:year]}"
        end

        if not filter_out
          article[:text] = Hash.new
          article[:text][:md] = body
          article[:text][:html] = md_to_html(body)
          @articles.push article
        end
      end
      @articles.sort_by!{|a| a[:timestamp]}.reverse!
    end 
  end

  def show
  end

  private

  def parse_file(f)
    fc = f.read
    if fc =~ /\A(---\n.*?\n)---\n(.*)\Z/m then
      return :yaml, $1, $2
    elsif fc =~ /\A(#.*?)\n\n(.*)\Z/m then
      return :free, $1, $2
    else
      return :bad, nil, nil
    end
  end

  def parse_yaml(h)
    YAML::load(h)
  end

  def parse_free(h)
    attrs = {'title' => 'ERROR', 'category' => 'ERROR', 'time' => nil}
    if h =~ /\A#+\s*(.+?)\n\s*\[(.+?)\]\s*\[(.+?)\]\s*\Z/m then
      attrs['title'] = $1.strip
      attrs['category'] = $2.strip
      attrs['time'] = $3.strip
    end
    attrs
  end

  def md_to_html(md)
    md = md.gsub(/{%.*?%}/, '')
    #Kramdown::Document.new(md).to_html
    Redcarpet::Markdown.new(MyRender, fenced_code_blocks: true).render(md)
  end

end
