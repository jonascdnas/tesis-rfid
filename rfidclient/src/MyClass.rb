require 'unirest'


class MyClass #(change name)
 
  include GladeGUI

  def filter_tags(tl, filter)
	  i=0
	  msg = ""
	  tl.each do |tag|
		  if tag.id =~ filter 
			  msg <<( i.to_s + "\t" + tag.id + "\r\n")
		  end
		  i+=1
	  end
	  return msg
  end

  # Takes a string returned from a Taglist function call and builds an array of tags.
  def build_tag_array(taglist_string)
	  tl = Array.new 
  # grab the taglist from the reader, split it into individual line entries...
	  lines = taglist_string.split("\r\n")
  # ...and build an array of tag objects
	  lines.each do |line|
		  if line =="(No Tags)" 
			  tl = []
		  else
			  tl.push(AlienTag.new(line))
		  end
	  end
	  return tl
  end


  def before_show()
    @path = File.dirname(__FILE__) + "/"
    @builder["image1"].file = @path + "escudo.jpg"
    @builder["image2"].file = @path + "nopase.jpg"

    @list_view = VR::ListView.new(:ident => String, :antena => String, :cadena => String)
#    @list_view.add_row(:ident => "00", :antena => "00", :cadena => "000 000 000")
    @builder["scrolledwindow1"].add_child(@builder, @list_view)
    @builder["window1"].show_all
  end  

#************************************
# Esta función verifica la conexión.
#************************************
  def button2__clicked(*args)
    @builder["label4"].label = "ok"
    config = AlienConfig.new("src/config.dat")
	  ipaddress = config["reader_ip_address"]
	  r = AlienReader.new
    r.open(ipaddress)
	  if r.open(ipaddress)
      @builder["label6"].label = "#{r.readername}"
      @builder["label8"].label = "#{r.readertype}"
    else
      @builder["label6"].label = "Error de conexión"
      @builder["label8"].label = "Error de conexión"	  
    end
    r.close
    STDERR.puts $!

    response = Unirest.get "http://localhost:8000/api/1/device/", auth:{:user=>"puerta1", :password=>"puerta1"}
    respmod = response.code.to_s    
#    puts respmod    

    if respmod == '200'
      @builder["label10"].label = "Activo"
    else
      @builder["label10"].label = "Error al conectar con el servidor"
    end
  end

  def button3__clicked(*args)
    reading = TRUE
  end


  def button1__clicked(*args)
    config = AlienConfig.new("src/config.dat")
	  ipaddress = config["reader_ip_address"]
	  r = AlienReader.new
	  if r.open(ipaddress)
        tl = build_tag_array(r.taglist)
        @builder["label11"].label = "Etiquetas leidas: " + tl.length.to_s
        
        i = 0
        tl.each do |tag|
          @list_view.add_row(:ident => i.to_s, :antena => "00", :cadena => tag.id)
          i+=1
        end

        dig_in = r.gpio

     r.close
	  end

    #puts tl.length
    if tl.length == 1
      #puts "http://localhost:8000/api/1/device/" + tl[0].to_s

      puts dig_in
      @builder["label14"].label = "GIPO In --> " + dig_in
      response = Unirest.get "http://localhost:8000/api/1/device/" + tl[0].to_s, auth:{:user=>"puerta1", :password=>"puerta1"}
      respmod = response.code.to_s 
      if respmod == '200'
        @builder["label13"].label = response.body[0].to_s
        @builder["image2"].file = @path + "pase.jpg"
      else
        @builder["label13"].label = "No encontrado"
        @builder["image2"].file = @path + "nopase.jpg"
      end
      respmod = response.body.to_s 
      #puts respmod
    else 
      @builder["label13"].label = "No hay etiquetas"
      @builder["image2"].file = @path + "nopase.jpg"
    end
  end

end
