import os
import htmlPy
import scale_serial
import time
# General setup for htmlypy

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
app = htmlPy.AppGUI(title=u"Wastebin", maximized=True)

# static is where all images , stylesheets anda javascripts are
app.static_path = os.path.join(BASE_DIR, "images/")

# files for template
# app.template_path = os.path.join(BASE_DIR, "templates/")

app.web_app.setMinimumWidth(1024)
app.web_app.setMinimumHeight(768)

# initialize html file here
app.html = u"Hellow World"
app.template_path = os.path.abspath(".")
app.static_path = os.path.abspath(".")
# initialize template here, input a dictionary
app.template = ("./index.html",{"template_variable_name": "value"})

# run javascript code
app.evaluate_javascript("carousel()")

# scale setup
#scale = scale_serial.Scale()

if __name__ == "__main__":
    print("test)")
    app.start()
    i = 1;
    while(true):
        i +=1
        print("lasting forever")
        if scale.ser.in_waiting >= 6:
            reading = scale.ser.read(6)
            while((len(reading) != 6 or reading[0] != 0xff)):
                scale.ser.close()
                scale.ser.open()
                reading = scale.ser.read(6)
            if(scale.check(reading)):
                # change the window to the thank you message
                # change html file here
                app.html = u"<html></html>"

                # change template here, input a dictionary
                app.template = (
                    "./index.html", {"template_variable_name": "value"})

                # keep it there for some time so people can see
                time.sleep(5)
                # change to the regular html
                app.html = u"<html></html>"

                # change to the usual template
                app.template = (
                    "./index.html", {"template_variable_name": "value"})
                app.evaluate_javascript("carousel()")
