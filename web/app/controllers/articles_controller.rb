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

  def initialize
    super
    @page_title = 'CodingINET.com'
  end

  def index
    @articles = Array.new
    @categories = Hash.new
    Pathname.glob('../blogs/*.md') do |path|
      article = parse_article(path, 20)
      next if (article == nil)

      count_categories(article, @categories)

      if params.has_key?(:cat)
        @tips = "Filtered by category: #{params[:cat]}"
        next if article[:attr]['category'] != params[:cat]
      end
      if params.has_key?(:year)
        @tips = "Filtered by year: #{params[:year]}"
        next if article[:timestamp].year.to_s != params[:year]
      end

      @articles.push article
    end 
    @articles.sort_by!{|a| a[:timestamp]}.reverse!
  end

  def view
    print "view #{params[:id]}\n"
    @categories = Hash.new
    Pathname.glob('../blogs/*.md') do |path|
      article = parse_article(path, -1)
      next if (article == nil)

      count_categories(article, @categories)

      @article = article if article[:id] == params[:id]
    end 
    if @article == nil then
      render :nothing => true, :status => 404
    elsif params[:simple] then
      render 'view_simple'
    end
  end

  private

  def count_categories(article, cat)
    count = cat[article[:attr]['category']]
    if count == nil
      cat[article[:attr]['category']] = 1;
    else
      cat[article[:attr]['category']] = count + 1
    end
  end

  def parse_article(path, min_lines)
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
        return nil
      end

      if article[:attr]['time']
        article[:timestamp] = article[:attr]['time']
      else
        est_time = article[:month].gsub(/^(....)(..)$/, '\1-\2-01 18:00 +0800')
        article[:timestamp] = Time.parse(est_time)
      end

      if min_lines > 0 then
        body, is_truncated = truncate_lines(body, min_lines)
      end

      article[:text] = Hash.new
      article[:text][:md] = body
      article[:text][:html] = md_to_html(body)
      article[:text][:is_truncated] = is_truncated
      return article
    end
    return nil
  end

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

  def truncate_lines(body, min_lines)
    lines = body.lines;
    if lines.count <= min_lines then
      return body, false
    end
    for i in min_lines...lines.count do
      if lines[i][0] != "\n" and lines[i-1][0] == "\n" then
        return lines[0...i].join, true
      end
    end
    return body, false
  end

  def md_to_html(md)
    md = md.gsub(/{%.*?%}/, '')
    #Kramdown::Document.new(md).to_html
    Redcarpet::Markdown.new(MyRender, fenced_code_blocks: true).render(md)
  end

end
