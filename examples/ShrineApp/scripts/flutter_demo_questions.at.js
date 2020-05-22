// {Name: Flutter_Demo_Questions}
// {Description: Flutter demo application, Questions}
// {Visibility: Admin}

question(`What can (you|I) do`, `What is this (app|application)`, p => {
    p.play(`(This is the Flutter Shrine demo app. With a visual voice experience powered by Alan Platform|) " +
        "You can use commands like: Order (a|the) (Gatsby hat|weave keyring|shrug bag|plaster tunic|sea tunic|clay sweater), ",
        "What products do you have, and Show (accessories|clothing|home items)`);

});

question(`What is Alan (AI|Platform)?`, p => {
    p.play(`Alan AI is a Voice AI platform that lets you add a (complete|) visual voice experience to any application. ` +
        `(The voice in this application is powered by Alan AI|)`);
});

question("Do you have $(R* .+)",
        "I want $(R* .+)",         
         p => {
            p.play(`No, we have no ${p.R.value}`)    
});

question(
    "What (kind|types) (of|) (items|products|items) do you have (to order|)",
    "What do you have (to order|)", "What is available",
    "What can I (order|have|get)", p => {
        p.play("We have several types of clothes, accessories, and home (items|goods) available. (What would you like to order?|)",
            "We offer clothes, accessories, and home (items|goods). (What would you like to order?|)");
    });

//Visual state related questions
question("What (screen|) is this?", "Where am I", "What commands can I use here", p => {
    if (!p.visual.screen) {
        p.play("This is the sample Flutter app powered by Alan Platform. Unfortunately, I am not able to say what screen you are on");
        return;
    }
    switch (p.visual.screen) {
        case "all":
            p.play("This is the main screen showing all available products. Here you can use commands like: Order (a|the) (Copper wire rack|blue stone mug|rainwater tray|quartet table|Gatsby hat|weave keyring|shrug bag|plaster tunic|sea tunic|clay sweater) " +
                "What products do you have? and Show (accessories|clothing|home items)?");
            break;
            
        case "clothing":
            p.play("These are all of the available clothing. (Here,|) you can (use commands|ask questions) like Order navy trousers and What types of clothing do you have?");
            break;
            
        case "accessories":
            p.play("These are all of the available accessories. (Here,|) you can (use commands|ask questions) like Order (gatsby hat|shrug bag) and What types of accessories do you have?");
            break;

        case "home":
            p.play("These are all of the available home (goods|items). (Here,|) you can (use commands|ask questions) like Order (gatsby hat|shrug bag) and What types of home (items|goods) do you have?");
            break;

        case "cart":
            p.play("This is your cart. (Here,|) you can ask questions about your order, change it or checkout");
            break;
    }
});
