/**
 * Storing var for interactions with scale 
 * @namespace Scale 
 */
var Scale = {};
Scale.newScaleValue = 0;
Scale.oldScaleValue = 0;
Scale.resultFilePath = "file:///home/kd/UCI-DWB/javascript_and_json/result.json"
Scale.binType = "default"

/** Store bin types and their respective data */
Scale.binTypeList = {
    "compost": {
        carbonConversionFactor: 0.3968316,
        options: {
            useEasing: true,
            useGrouping: true,
            separator: '',
            decimal: '.',
            suffix: ' ounces!'
        },
        options2: {
            useEasing: true,
            useGrouping: true,
            separator: '',
            decimal: '.',
            prefix: 'You just helped avoid </br>',
            suffix: ' ounces'
        }
    },

    "recycle": {
        carbonConversionFactor: 3.1526066,
        options: {
            useEasing: true,
            useGrouping: true,
            separator: '',
            decimal: '.',
            suffix: ' ounces!'
        },
        options2: {
            useEasing: true,
            useGrouping: true,
            separator: '',
            decimal: '.',
            prefix: 'You just helped avoid </br>',
            suffix: ' ounces'
        }
    },

    "landfill": {
        carbonConversionFactor: 0,
        options: {
            useEasing: true,
            useGrouping: true,
            separator: '',
            decimal: '.',
            suffix: ' ounces'
        }
    }
}

runProgram();
carousel();

/**
 * The main function, used to constantly check the scale value and call special effects if things change
 */
async function runProgram() {
    var objDate = new Date();
    var sec1 = objDate.getSeconds();
    var sec2 = sec1;
    var objDate2;
    while (true) {
        objDate2 = new Date();
        sec2 = objDate2.getMilliseconds();
        await sleep(100); //sleep for 100 ms
        readTextFile(Scale.resultFilePath);
        console.log(Scale.newScaleValue);

        // start display if new value different from prev value
        if (Scale.oldScaleValue != Scale.newScaleValue) {
            Scale.oldScaleValue = Scale.newScaleValue;
            console.log("IT is different");
            var ouncesCarbonSaved = Scale.binTypeList[Scale.binType].carbonConversionFactor * Scale.newScaleValue;
            var r1 = document.getElementById("antpopup");
            var r2 = document.getElementById("SlideShow");
            //var s1 = document.getElementsByClassName('mySlides')[0];
            var pop = document.getElementsByClassName('popup')[0];
            var bot1 = document.getElementById("bot");
            var bot3 = document.getElementsByClassName('bot2')[0];
            //s1.classList.add('fadeo');
            await sleep(1000);
            r2.style.visibility = "hidden";
            //s1.classList.remove('fadeo');
            bot1.style.visibility = "visible";
            r1.style.visibility = "visible";
            pop.classList.add('bounceup');
            bot3.classList.add('bounceup');
            await sleep(1000);
            pop.classList.remove('bounceup');
            bot3.classList.remove('bounceup');

            // start counting animations based on the bin type
            if (Scale.binType != "landfill") {
                var numAnim = new CountUp("tbox", 0.0, Scale.newScaleValue, 3, 2, Scale.binTypeList[Scale.binType].options);
                if (!numAnim.error) {
                    numAnim.start();
                } else {
                    console.error(numAnim.error);
                }
                var numAnim2 = new CountUp("2box", 0.0, ouncesCarbonSaved, 3, 2, Scale.binTypeList[Scale.binType].options2);
                if (!numAnim2.error) {
                    numAnim2.start();
                } else {
                    console.error(numAnim2.error);
                }
            }
            else {
                var numAnim = new CountUp("tbox", 0.0, Scale.newScaleValue, 3, 2, Scale.binTypeList[Scale.binType].options);
                if (!numAnim.error) {
                    numAnim.start();
                } else {
                    console.error(numAnim.error);
                }
            }

            await sleep(8000);
            pop.classList.add('fadeo');
            bot3.classList.add('fadeo');
            await sleep(1000);
            pop.classList.remove('fadeo');
            bot3.classList.remove('fadeo');
            //s1.classList.add('fadeleft');
            bot1.style.visibility = "hidden";
            r1.style.visibility = "hidden";
            r2.style.visibility = "visible";

        }
    }
}

/**
 * Used for reading the text file written by the scale driver
 * @param {*} file json file containg the type and the weight value 
 */
async function readTextFile(file) {

    // response code obtained from javascript docs
    const HTTP_REQUEST_DONE = 0;
    const REQUEST_READY = 4;

    var scaleResult = {};
    var scaleReq = new XMLHttpRequest();
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
    // https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/readyState
    // TODO: error handling if open fails
    // need --allow-file-access-from-files flag to work
    scaleReq.open('GET', file, false);
    scaleReq.send(null);

    if (scaleReq.status == HTTP_REQUEST_DONE && scaleReq.readyState == REQUEST_READY) {
        scaleResult = JSON.parse(scaleReq.responseText);
    }
    else {
        // error handling here
    }
    Scale.newScaleValue = scaleResult.weight;
    Scale.binType = scaleResult.binType;
}

/**
 * Used to create slideshow and change image every once in a while
 */
async function carousel() {
    var carouselIndex = 0;
    while (true) {
        var i;
        var slideShow = document.getElementsByClassName("mySlides");
        for (i = 0; i < slideShow.length; i++) {
            slideShow[i].style.display = "none";
        }
        carouselIndex++;
        if (carouselIndex > slideShow.length) { carouselIndex = 1 }
        slideShow[carouselIndex - 1].style.display = "block";
        await sleep(8000); //change image every 8 seconds
    }
}
