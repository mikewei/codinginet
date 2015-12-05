require 'kramdown'

class ArticlesController < ApplicationController

  def index
    @articles = Array.new
    @categories = Hash.new
    Pathname.glob('../blogs/*') do |path|

      fn = path.basename.to_s
      fn =~ /^((\d{6})-([^.]+))\.(\w+)$/
      article = { id: $1, month: $2, name: $3, type: $4 }

      path.open("r") do |f|
        head, body = parse_file(f)
        article[:attr] = parse_yaml(head)

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
    end 
  end

  def show
  end

  private

  def parse_file(f)
    f.read =~ /^(---\n.*?\n)---\n(.*)$/m
    return $1, $2
  end

  def parse_yaml(h)
    YAML::load(h)
  end

  def md_to_html(md)
    md = md.gsub(/{%.*?%}/, '')
    Kramdown::Document.new(md).to_html
  end

end
