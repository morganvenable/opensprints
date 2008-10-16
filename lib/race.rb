class Race
  attr_accessor :red_racer, :blue_racer, :green_racer, :yellow_racer
  def initialize(red_racer, blue_racer, green_racer, yellow_racer, distance)
    red_racer.ticks = 0 if red_racer
    blue_racer.ticks = 0 if blue_racer
    green_racer.ticks = 0 if green_racer
    yellow_racer.ticks = 0 if yellow_racer
    @red_racer = red_racer
    @blue_racer = blue_racer
    @green_racer = green_racer
    @yellow_racer = yellow_racer
    @distance = distance    
  end

  def racers
    [@red_racer,@blue_racer,@green_racer,@yellow_racer].compact
  end
  
  def add_racer(racer)
    racer.ticks.clear
    if red_racer && blue_racer && green_racer
      @yellow_racer = racer    
      else if red_racer && blue_racer
        @green_racer = racer   
        else if red_racer
          @blue_racer = racer
          else      
            @red_racer = racer
        end
      end
    end    
  end

  def complete?
    self.racers.all? { |racer| racer.finish_time }
  end

  def winner
    standings = self.racers.sort_by { |racer| racer.finish_time }

    winner = standings.first
    standings.reverse.each_with_index do |racer, i|
      racer.wins += i
      racer.races += 1
      racer.record_time(racer.finish_time)
    end
    winner
  end

  def flip
    @red_racer, @blue_racer = @blue_racer, @red_racer
  end

end
