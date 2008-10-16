module RacePresenterMod
  def race_window(match, race_distance, sensor, title)
    window :title => title, :width => 800, :height => 600 do
      #background "media/trappedsprints-800.jpg"

      stack do
        subtitle title, :top => 150, :align => "center", :background => magenta,
          :stroke => white
        @update_area = stack {}

        def hide_start
          @start.hide
        end

        @start = button("Start Race",{:top => 570, :left => 10}) do
          hide_start
          r = RacePresenter.new(self, race_distance, @update_area,
                       match, sensor)
          
          sensor.start
          @countdown = 4
          @start_time = Time.now+@countdown
          count_box = stack(:top => 200){   }
          @race_animation = animate(14) do
            @now = Time.now
            if @now < @start_time
              count_box.clear do
                banner "#{(@start_time-@now).round}...", :stroke => ivory,
                  :font => "Arial 200px", :align => 'center'
              end
            else
              count_box.remove
              r.refresh
              @start.show unless r.continue?
            end
          end
        end

        button("Quit", {:top => 570, :left => 135}) do
          @race_animation.stop if @race_animation
          close
        end
      end
    end
  end

end
class RacePresenter
  def initialize(shoes_instance, distance, update_area, race, sensor)
    @shoes_instance = shoes_instance
    @bar_size = 800-2*60-6
    @race_distance = distance
    @race = race
    @red = @race.red_racer
    @blue = @race.blue_racer
    @green = @race.green_racer
    @yellow = @race.yellow_racer
    @update_area = update_area
    @sensor = sensor
  end


  def continue?; @continue end

  def refresh
    unless @started
      @started=true
      @continue = true
    end
    
    @red.ticks = @sensor.values[:red].size  if not @red == nil
    @blue.ticks = @sensor.values[:blue].size if not @blue == nil
    @green.ticks = @sensor.values[:green].size if not @green == nil
    @yellow.ticks = @sensor.values[:yellow].size if not @yellow == nil


    @update_area.clear do
      @shoes_instance.stroke gray 0.5
      @shoes_instance.strokewidth 4
      @foo = @shoes_instance.image(800-60+4, 200, :top => 280, :left => 80) do
        @shoes_instance.line 2,0,2,200
        @shoes_instance.line 684,0,684,200

        red_progress = @bar_size*percent_complete(@red)
        @shoes_instance.stroke "#F00"
        @shoes_instance.fill "#FEE".."#F23", :angle => 90, :radius => 10
        @shoes_instance.rect 6, 20, red_progress, 20 

        blue_progress = @bar_size*percent_complete(@blue)
        @shoes_instance.stroke "#00F"
        @shoes_instance.fill "#FEE".."#32F", :angle => 90, :radius => 10
        @shoes_instance.rect 6, 60, blue_progress, 20 
        
        green_progress = @bar_size*percent_complete(@green)
        @shoes_instance.stroke "#0F0"
        @shoes_instance.fill "#FEE".."#2F3", :angle => 90, :radius => 10
        @shoes_instance.rect 6, 100, green_progress, 20 

        yellow_progress = @bar_size*percent_complete(@yellow)
        @shoes_instance.stroke "#FF0"
        @shoes_instance.fill "#FEE".."#FF2", :angle => 90, :radius => 10
        @shoes_instance.rect 6, 140, yellow_progress, 20 

        
      end

      @foo.translate(0,-75)
      @shoes_instance.subtitle(
        @shoes_instance.span(@red.name,{:stroke => "#F00"}),         
        @shoes_instance.span(@blue.name,{:stroke => "#00F"}),
        @shoes_instance.span(@green.name,{:stroke => "#0F0"}), 
        @shoes_instance.span(@yellow.name,{:stroke => "#FF0"}),
        {:top => 400, :align => 'center'})
      
      @red.finish_time = @sensor.values[:red][ticksInRace]
      @blue.finish_time = @sensor.values[:blue][ticksInRace]
      @green.finish_time = @sensor.values[:green][ticksInRace]
      @yellow.finish_time = @sensor.values[:yellow][ticksInRace]

      if @race.complete?
        @shoes_instance.title "#{@race.winner.name.upcase} WINS!!!\n", :align => "center",
         :top => 380, :width => 800, :stroke => @shoes_instance.ivory
        @shoes_instance.title "#{@red.name}: #{@red.finish_time/1000.0}s, #{@blue.name}: #{@blue.finish_time/1000.0}s, #{@green.name}: #{@green.finish_time/1000.0}s, #{@yellow.name}: #{@yellow.finish_time/1000.0}s", :stroke => @shoes_instance.ivory,
          :align => 'center', :top => 450, :width => 800

        @sensor.stop
        @continue = false
        @shoes_instance.owner.tournament_record(@race)
        @shoes_instance.owner.post_race
      end
    end
  end

  def percent_complete(racer)
    [1.0, ((racer.ticks * racer.roller_circumference) || 0)/@race_distance.to_f].min
  end
  
  def ticksInRace
    (@race_distance/@red.roller_circumference)
  end

end
