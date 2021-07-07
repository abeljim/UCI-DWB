# Scale

## Scale Software

- The scale program usually runs in a separate thread and modify a json file so that the display thread can read the scale output
- During the parsing process, a lot of checking is placed to make sure we don't process the same data in a row and waste computing power
- The buffer is flushed every read to prevent congestion

## Scale Hardware

- The scale used is the global 240878, the manual is pretty sparse, but for now, it's the best we can find, we can't control it.
- The unit used should be lbs 

https://www.globalindustrial.com/p/packaging/scales/counting/electronic-counting-scale-60-lb-capacity
