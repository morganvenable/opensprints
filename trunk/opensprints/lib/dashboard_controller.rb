require 'thread'
class DashboardController
 
  def DashboardController.rgb(r,g,b)
    Gdk::Color.new((r*65535)/255,(g*65535)/255,(b*65535)/255)
  end 
  @@gray = rgb(61, 52, 53)
  def rgb(r,g,b)
    self.class.rgb(r,g,b)
  end
  
  def make_layout(cr, text, size, bold = nil)
    layout = cr.create_pango_layout
    layout.text = text
    layout.font_description = 
      Pango::FontDescription.new("DIN 1451 Std #{bold} #{size.to_s}")
    cr.update_pango_layout(layout)
    layout
  end

  def initialize(context, racer1, racer2)
    @red = Racer.new(:wheel_circumference => RED_WHEEL_CIRCUMFERENCE,
                     :track_length => 1315, :yaml_name => '1',
                     :name => racer1)
    @blue = Racer.new(:wheel_circumference => BLUE_WHEEL_CIRCUMFERENCE,
                      :track_length => 1315, :yaml_name => '2',
                      :name => racer2)
    @continue = false
    @last_time = '0:00:00'
#   sp = Cairo::SurfacePattern.new(Cairo::ImageSurface.from_png('views/mockup.png'))
#   context.set_source(sp)
       
    context.set_source_color @@gray
    context.paint
    context.set_source_color rgb(252,252,252)
    context.rectangle(30, 97, 157, 1)
    context.rectangle(210, 97, 530, 1)
    context.fill
#start/end labels
    context.set_source_color rgb(203,195,192)
    context.rectangle(27, 129, 19, 189)
    context.rectangle(727, 129, 19, 189)
#progress borders
    context.rectangle(27, 129, 718, 1)
    context.rectangle(27, 318, 718, 1)
    context.fill

#statboxes
    context.set_source_color rgb(165,86,64)
    context.rectangle(27, 357, 226, 99)
    context.fill
    context.set_source_color rgb(77,134,161)
    context.rectangle(269, 357, 226, 99)
    context.fill
#nameboxes
    context.set_source_color rgb(207,95,55)
    context.rectangle(27, 332, 226, 25)
    context.fill
    context.set_source_color rgb(65,167,207)
    context.rectangle(269, 332, 226, 25)
    context.fill
#status box
    context.set_source_color rgb(203,195,192)
    context.rectangle(27, 471, 718, 98)
    context.stroke
# START
    context.set_source_color @@gray
    context.move_to(44, 316)
    context.line_to(44, 0)
    path = context.copy_path_flat
    context.new_path
    start_text = make_layout(context, 'START', 16, 'bold')
    context.pango_layout_line_path(start_text.get_line(0))
    context.map_path_onto(path)
    context.fill

# FINISH
    context.new_path
    context.set_source_color @@gray
    context.move_to(745, 316)
    context.line_to(745, 0)
    path = context.copy_path_flat
    context.new_path
    finish_text = make_layout(context, 'FINISH', 16, 'bold')    
    context.pango_layout_line_path(finish_text.get_line(0))
    context.map_path_onto(path)
    context.fill

# IRO
    context.new_path
    context.set_source_color rgb(255,255,0)
    context.move_to(70, 90)
    context.line_to(500,90)
    path = context.copy_path_flat
    context.new_path
    iro_text = make_layout(context, 'IRO', 42)    
    context.pango_layout_line_path(iro_text.get_line(0))
    context.map_path_onto(path)
    context.fill

# Sprints
    context.new_path
    context.set_source_color rgb(255,255,255)
    context.move_to(160, 90)
    context.line_to(600,90)
    path = context.copy_path_flat
    context.new_path
    iro_text = make_layout(context, 'Sprints', 42)    
    context.pango_layout_line_path(iro_text.get_line(0))
    context.map_path_onto(path)
    context.fill

# Racer1
    context.new_path
    context.set_source_color @@gray
    context.move_to(30, 352)
    context.line_to(600,352)
    path = context.copy_path_flat
    context.new_path
    iro_text = make_layout(context, @red.name, 16)    
    context.pango_layout_line_path(iro_text.get_line(0))
    context.map_path_onto(path)
    context.fill
    context.stroke

# Racer2
    context.new_path
    context.set_source_color @@gray
    context.move_to(272, 352)
    context.line_to(600,352)
    path = context.copy_path_flat
    context.new_path
    iro_text = make_layout(context, @blue.name, 16)    
    context.pango_layout_line_path(iro_text.get_line(0))
    context.map_path_onto(path)
    context.fill

    @last_blue_tick = [45,318]
    @last_red_tick = [45,318]
    @context = context

    @width = context.line_width
    @cap = context.line_cap
  end
  
  def start
    @continue = true
    @queue = Queue.new
    @sensor = Sensor.new(@queue, SENSOR_LOCATION)
    @sensor.start
  end
  def stop
    @sensor.stop
  end

  def refresh
    partial_log = []
    @queue.length.times do
      q = @queue.pop
      if q =~ /;/
        partial_log << q
      end
    end
    if (partial_log=partial_log.grep(/^[12]/)).any?
      @last_time = timeize(SecsyTime.parse(partial_log[-1].split(";")[1]))
      if (blue_log = partial_log.grep(/^2/))
        @blue.update(blue_log)
      end
      if (red_log = partial_log.grep(/^1/))
        @red.update(red_log)
      end
      if @blue.distance>RACE_DISTANCE and @red.distance>RACE_DISTANCE
        winner = (@red.last_tick<@blue.last_tick) ? @red : @blue
        
        puts "#{@red.name}: #{@red.last_tick}"
        puts "#{@blue.name}: #{@blue.last_tick}"
        @sensor.stop
        @blue_display_speed = @blue.last_tick.to_s
        @red_display_speed = @red.last_tick.to_s
      
        @continue = false
      else
        @blue_display_speed = [@blue.speed.round.to_i,99].min.to_s
        @red_display_speed = [@red.speed.round.to_i,99].min.to_s
      end

        blue_progress = 685*@blue.percent_complete
        @context.set_source_color rgb(54,127,155) 
        @context.rectangle(47, 150, blue_progress, 20)
        @context.fill
#        @surface.draw_box_s([269, 357], [495, 456], [77,134,161])
        
        red_progress = 685*@red.percent_complete 
        @context.set_source_color rgb(159,77,56)
        @context.rectangle(47, 129, red_progress, 20)
        @context.fill
        
        #progress bar separators
#        @surface.draw_box_s([27, 357], [253, 456], [165,86,64])
        @context.set_source_color rgb(203,195,192) 
        @context.rectangle(27, 129, 718, 1)
        @context.rectangle(27, 149, 718, 1)
        @context.rectangle(27, 170, 718, 1)
        @context.fill

        @context.line_width = 3
        @context.line_cap = Cairo::LineCap::ROUND
        tick_at = graph_tick(@red.percent_complete, @red.speed)
        @context.set_source_color rgb(159,77,56)
        @context.move_to(*@last_red_tick)
        @context.curve_to(*(@last_red_tick+tick_at+tick_at))
        @context.stroke
        @last_red_tick = tick_at
        
        tick_at = graph_tick(@blue.percent_complete, @blue.speed)
        @context.set_source_color rgb(54,127,155)
        @context.move_to(*@last_blue_tick)
        @context.curve_to(*(@last_blue_tick+tick_at+tick_at))
        @context.stroke
        @last_blue_tick = tick_at
#Draw red speed
        @context.set_source_color rgb(165,86,64)
        @context.rectangle(27, 357, 226, 99)
        @context.fill
        @context.new_path
        @context.move_to(30, 450)
        @context.line_to(600,450)
        path = @context.copy_path_flat
        @context.new_path
        iro_text = make_layout(@context, @red_display_speed, 76, 'bold')    
        @context.pango_layout_line_path(iro_text.get_line(0))
        @context.map_path_onto(path)
        @context.set_source_color rgb(207,95,55)
        @context.fill
#Draw blue speed
        @context.set_source_color rgb(77,134,161)
        @context.rectangle(269, 357, 226, 99)
        @context.fill
        @context.new_path
        @context.move_to(272, 450)
        @context.line_to(600,450)
        path = @context.copy_path_flat
        @context.new_path
        iro_text = make_layout(@context, @blue_display_speed, 76, 'bold')    
        @context.pango_layout_line_path(iro_text.get_line(0))
        @context.map_path_onto(path)
        @context.set_source_color rgb(65,167,207)
        @context.fill
        @context.line_width = @width
        @context.line_cap = @cap
        @continue = true
    end
    @context.rectangle(610, 325, 140, 40)
    @context.set_source_color @@gray
    @context.fill
    @context.new_path
    @context.set_source_color rgb(255,255,255)
    @context.move_to(610, 350)
    @context.line_to(740,350)
    path = @context.copy_path_flat
    @context.new_path
    iro_text = make_layout(@context, @last_time, 24, true)    
    @context.pango_layout_line_path(iro_text.get_line(0))
    @context.map_path_onto(path)
    @context.fill
  end
  def continue?
    @continue
  end


  def graph_tick(percent, speed)
    [(percent*(726-45) + 47),
     (147 - ([speed,50.0].min/50.0 * 147) + 171)]
  end

  def timeize(t)
    "%1i:%02i.%02i" % [(t.mins),(t.secs),(t.hunds)]
  end
end
