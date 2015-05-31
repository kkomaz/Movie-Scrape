class Movie
  attr_accessor :title, :budget, :release_date

  @@instances = []

  def initialize(title, budget, release_date)
    @title = title
    @budget = budget
    @release_date = release_date
    @@instances << self
  end

  def self.all
    @@instances
  end

  def self.no_budget
    self.all.select { |movie| movie.budget == 0}.count
  end

  def self.true_count
    self.all.count - self.no_budget
  end

  def self.movies_detail
    self.all.each.with_index(1) do |movie, index|
      print "#{index}. #{[movie.title, movie.budget, movie.release_date]}"
      puts ""
    end
  end

  def self.price_converter
    self.all.each do |movie|
      if movie.budget.include?("million")
        movie.budget = (movie.budget.gsub("million", "").to_f * 1_000_000)
      elsif movie.budget.include?("billion")
        movie.budget = (movie.budget.gsub("billion", "").to_f * 1_000_000_000)
      elsif movie.budget.include?(",") && movie.budget.include?("£")
        movie.budget = (movie.budget.gsub("£", "").gsub(",","").to_f * 1.53)
      elsif movie.budget.include?(",")       
        movie.budget = (movie.budget.gsub(",","")).to_f
      else
        movie.budget = movie.budget.to_f
      end
    end
  end

  def self.average_budget
    sum = self.all.collect {|movie| movie.budget}.inject(:+)
    puts "Average Budget: #{(sum / (self.true_count) / 1_000_000).round(2)} million"
  end
end
