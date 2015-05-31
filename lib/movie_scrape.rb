class MovieScrape

  attr_accessor :urls

  BASE_URL = "https://en.wikipedia.org/wiki/Academy_Award_for_Best_Picture"
  MOVIE_URL = "https://en.wikipedia.org"

  def call
    scrape_all_urls
    create_movie_objects
    Movie.price_converter
    Movie.movies_detail
    Movie.average_budget
  end

  def scrape_all_urls
    movies_url = open(BASE_URL)
    movies_index = Nokogiri::HTML(movies_url)

    @urls = movies_index.search("table.wikitable").collect do |movie|
      movie.search('tr[style*="background:#FAEB86"]').search("a").first.attributes["href"].value
    end
  end

  def create_movie_objects
    @urls.each do |url|
      get_movie_data(url)
    end
  end

  def get_movie_data(url)
    movie_url = open("#{MOVIE_URL}#{url}")
    movie_index = Nokogiri::HTML(movie_url)
    movie_box = find_box(movie_index)
    title = movie_box.first.text.gsub("\n","")    
    elements = movie_box.each_with_index.map { |tr, i| categorize_elements(tr,i) }.compact
    filter_and_create(movie_box, title, elements)
  end

  private

  def categorize_elements(tr, i)
    if tr.children[1].text == "Budget" 
        {"Budget" => i}
    elsif tr.children[1].text.gsub("\n","") == "Release dates"
        {tr.children[1].text.gsub("\n","") => i}
    end
  end

  def find_box(movie_index)
    movie_index.search("table.infobox.vevent").first.search("tr")
  end

  def date_filter(date)
    Date.parse(date).year
  end

  def filter_and_create(movie_box, title, elements)
    if movie_box.at('th:contains("Budget")')
      budget = movie_box[elements.last["Budget"]].search('td').first.children.text.gsub("US", "").gsub("\n","").gsub("$","").gsub(/\(.*?\)/, '')
      release_date = initial_date_filter(movie_box, elements)
    else
      # 0 indicates no data
      budget = '0'
      release_date = initial_date_filter(movie_box, elements)
    end    
    release_date = final_date_filter(release_date)
    budget = final_budget_filter(budget)
    Movie.new(title, budget, release_date)
  end

  def initial_date_filter(movie_box, elements)
    movie_box[elements.first["Release dates"]].search('td ul li').empty? ? movie_box[elements.first["Release dates"]].search('td').first.children.text.gsub(/\(.*?\)/, '').gsub("\n","") : movie_box[elements.first["Release dates"]].search('td ul li').first.text.gsub(/\(.*?\)/, '')
  end

  def final_date_filter(release_date)
    release_date.include?("(") ?  date_filter(release_date.slice(0...(release_date.index('(')))) : date_filter(release_date)
  end

  def final_budget_filter(budget)
    budget.include?("[") ?  budget = budget.slice(0...(budget.index('['))) : budget
  end
end



