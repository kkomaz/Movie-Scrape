class MovieScrape

  attr_accessor :urls, :year

  BASE_URL = "https://en.wikipedia.org/wiki/Academy_Award_for_Best_Picture"
  MOVIE_URL = "https://en.wikipedia.org"

  def call
    create_movie_objects
    # Movie.price_converter
    Movie.movies_detail
    Movie.average_budget
  end

  def create_movie_objects
    movies_url = open(BASE_URL)
    movies_index = Nokogiri::HTML(movies_url)

    movies_index.search("table.wikitable").each do |movie|
      year = movie.search('caption big').collect {|year_date| year_date.text.include?("[") ? year_date.text.split("[")[0] : year_date.text }
      movie_url = movie.at_css('td a')[:href]
      get_movie_data(movie_url, year)
    end
  end

  def get_movie_data(url, year)
    movie_url = open("#{MOVIE_URL}#{url}")
    movie_index = Nokogiri::HTML(movie_url)
    movie_box = find_box(movie_index)

    title = movie_box.first.text.gsub("\n","")
    budget = filter_budget(movie_box)
    release_date = year.join("")
    Movie.new(title, budget, release_date)
  end

  private

  def filter_budget(movie_box)
    if movie_box.at('th:contains("Budget")')
      budget = movie_box.search("[text()*='Budget']").last.next_element.text.gsub("US", "").gsub("\n","").gsub("$","").gsub(/\(.*?\)/, '')
    else
      budget = "0"
    end
    budget = final_budget_filter(budget)
    if budget.include?("million")
        budget = (budget.gsub("million", "").to_f * 1_000_000)
    elsif budget.include?("billion")
        budget = (budget.gsub("billion", "").to_f * 1_000_000_000)
    elsif budget.include?(",") && budget.include?("£")
        budget = (budget.gsub("£", "").gsub(",","").to_f * 1.53)
    elsif budget.include?(",")       
        budget = (budget.gsub(",","")).to_f
    else
        budget = budget.to_f
    end
    budget
  end

  def find_box(movie_index)
    movie_index.search("table.infobox.vevent").first.search("tr")
  end

  def final_budget_filter(budget)
    budget.include?("[") ?  budget = budget.slice(0...(budget.index('['))) : budget
  end
end