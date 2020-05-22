// {Name: Flutter_Demo_Logic}
// {Description: Flutter demo application, Logic}
// {Visibility: Admin}

const categoryAliases = {
    "clothes": "clothing",
    "clothing": "clothing",
    "clothings": "clothing",
    "accessories": "accessories",
    "home": "home",
    "home items": "home",
    "home goods": "home"
};

const items = _.reduce(project.products, (a, p) => {
    let name = p.name.toLowerCase();
    a[name] = a[name + "s"] = a[name + "es"] = p;
    return a
}, {});

const TYPES = _.reduce(project.products, (a, p) => {
    if (!p.type) return a;
    let type = p.type.toLowerCase();
    a[type] = a[type + "s"] = a[type + "es"] = type;
    return a
}, {});


onCreate(()=> {
        project.items_intent = project.products.map(p => p.name.toLowerCase() + '_').join('|');
        project.items_plural_intent = _.difference(Object.keys(items), project.products.map(p => p.name.toLowerCase())).join('|');
})

const CAT_INTENTS = Object.keys(categoryAliases).join('|');
const TYPE_INTENTS = _.uniq(project.products.filter(p => !_.isEmpty(p.type)).map(p => p.type + '_')).join('|');

let confirm = context(() => {
    follow('(yes|ok|correct|procede|confirm|continue|next|go on)', p => {
        p.play({command: "finishOrder"});
        p.play("Your order has been confirmed, thank you!");
        p.resolve(null);
    });

    follow('(no|change|invalid|nope|not correct|stop|back)', p => {
        p.play({command: 'navigation', route: '/cart'});
        p.play("OK, please (make neccessary corrections|update an order|fix what you want)");
        p.resolve(null);
    });
});

let howMany = context(() => {
    follow('$(NUMBER) $(W* .*)', p => p.resolve(p.NUMBER.number));

    follow('(Cancel|abort|that is not what I wanted)', p => {
        p.resolve(null);
    });
});

const repeatListItems = context(() => {
    title("repeat items");

    follow("(yes|sure|ok|next|show more)", p => {
        let {state} = p;
        if (!state.items) {
            p.play("There are no items");
            p.print("There are no items");
            return;
        }
        if (state.from + state.step > state.items.length) {
            state.step = state.from + state.step - state.items.length + 1;
        }
        let to = Math.min(state.from + state.step, state.items.length);
        let showItems = state.items.slice(state.from, to);
        if (_.isEmpty(showItems)) {
            p.play(`There are no more ${state.type}`);
            p.resolve(null);
            return;
        } else {
            showItems.forEach(item => {
                p.play({
                    command: 'highlight' + state.type,
                    value: state.id(item)
                });
                p.play(state.name(item));
            });
            p.play({command: 'highlight' + state.type, value: null});
            if (to < state.items.length) {
                p.play(`Do you want to hear more?`);
            }
        }
        p.state.from = to;
    });

    follow("(repeat|repeat please|say again)", p => {
        let {state} = p;
        if (!state.items) {
            p.play("There are no items");
            p.print("There are no items");
            return;
        }
        let showItems = state.items.slice(state.from - state.step, state.from);
        showItems.forEach(item => {
            p.play({
                command: 'highlight' + state.type,
                value: state.id(item)
            });
            p.play(state.name(item));
        });
        p.play({command: 'highlight' + state.type, item: null});
        if (state.from < state.items.length) {
            p.play(`Do you want to hear more?`);
        }
    });

    follow("(no|next time|not now|later|nope|stop)", p => {
        if (!p.state.items) {
            p.play("No items");
            return;
        }
        p.play("OK");
        p.resolve(null);
    });
});

const vOrder = visual(state => state.screen === 'cart');
intent(vOrder, "(back|close)", p => {
    p.play({command: 'navigation', route: 'back'})
});

intent(
    `Do you have $(CAT ${CAT_INTENTS})`,
    `What (types of|kinds of|) $(CAT ${CAT_INTENTS}) (do you have|are available)`,
    `(What|How) about $(CAT ${CAT_INTENTS})`,
    `(Show|Open) $(CAT ${CAT_INTENTS}) (menu|)`, p => {
        let cat = categoryAliases[p.CAT.toLowerCase()];
        let prods = project.products.filter(i => i.category === cat);
        p.play({command: 'navigation', route: '/' + cat});
        p.play(`From ${p.CAT} we offer: `, `We offer several ${cat} items`);
        playList(p, prods, "Products", item => item.name, item => item.id, true);
    });

intent(`Show all`, p => {
    p.play({command: 'navigation', route: '/all'});
    p.play(`Showing all available items.`,`(OK.|Done.|OK. Done.|)`);
});

intent(`(Order|get me|add) $(NUMBER) $(CAT ${CAT_INTENTS})`,
    `$(NUMBER) $(CAT ${CAT_INTENTS})`,
    `(Order|get me|add) $(CAT ${CAT_INTENTS})`, p => {
        let cat = categoryAliases[p.CAT.toLowerCase()];
        let prods = project.products.filter(i => i.category === cat);
        p.play({command: 'navigation', route: '/' + cat});
        p.play(`Which ${p.CAT} would you like? (We have several available:|${p.CAT} available:)`);
        playList(p, prods, "Products", item => item.name, item => item.id, true);
    });

//8-9
intent('(add|I want|order|get|and|) $(NUMBER) $(ITEM p:items_intent)',
    '(add|I want|order|get me|) $(NUMBER) $(ITEM p:items_intent) and $(NUMBER) $(ITEM p:items_intent)',
    '(add|I want|order|get me|) $(NUMBER) $(ITEM p:items_intent) and $(ITEM p:items_intent)',
    '(add|I want|order|get me|) $(ITEM p:items_intent) and $(ITEM p:items_intent)',
    '(add|I want|order|get me|and|) $(ITEM p:items_intent)',
    p => {
        let pItems = p.ITEMs ? p.ITEMs.map(i => i.value) : [];
        let pNumbers = p.NUMBERs ? p.NUMBERs.map(i => i.number) : [];
        addItems(p, pItems, pNumbers, 0)
    });

intent(`(add|I want|order|get me|) $(ITEM p:items_intent) and $(NUMBER) $(ITEM p:items_intent)`,
    p => {
        let pItems = p.ITEMs ? p.ITEMs.map(i => i.value) : [];
        let pNumbers = p.NUMBERs ? p.NUMBERs.map(i => i.number) : [];
        addItems(p, pItems, pNumbers, 1)
    });

intent(`(order|get me|add) (few|some) $(ITEM p:items_plural_intent)`,
    async p => {
        p.play(`OK, how many ${p.ITEM} would you like (to add|)`);
        let number = await p.then(howMany);
        if (number) {
            addItems(p, [p.ITEMs[0].value], [number], 0);
        } else {
            p.play("(OK|I see|No problem)");
        }
    });

//change
intent(`change (one of |) the $(ITEM p:items_intent) to a $(ITEM p:items_intent)`,
    p => {
        if (p.ITEMs && p.ITEMs.length !== 2) {
            p.play("Sorry, you should provide exactly two items in this request");
            return;
        }
        let id_del = items[p.ITEMs[0].value.toLowerCase()];
        if (!id_del) {
            p.play(`Can't find ${p.ITEMs[0]} in menu`);
        } else {
            let id_add = items[p.ITEMs[1].value.toLowerCase()];
            let name_add = p.ITEMs[1].value;
            if (!id_add) {
                p.play(`Can't find ${p.ITEMs[1]} in menu`);
            } else {
                p.state.lastId = id_add;
                p.state.lastName = name_add;
                let number_del = p.NUMBERs && p.NUMBERs[0] ? p.NUMBERs[0].number : 1;
                let number_add = p.NUMBERs && p.NUMBERs[1] ? p.NUMBERs[1].number : 1;
                let postfix_add = "";
                let postfix_del = "";
                p.play({command: 'removeFromCart', item: id_del, quantity: number_del});
                p.play({command: 'addToCart', item: id_add, quantity: number_add});
                p.play(`Removed ${number_del} ${p.ITEMs[0]} ${postfix_del} and added ${number_add} ${p.ITEMs[1]} ${postfix_add}`);
            }
        }
        p.play({command: 'navigation', route: '/cart'});
    });

//10
intent(`add (another|) $(NUMBER) more`, `add another`, p => {
    if (p.state.lastId) {
        let number = p.NUMBER && p.NUMBER.number > 0 ? p.NUMBER.number : 1;
        if (number > 99) {
            p.play(`Sorry, number is too high.`);
            return;
        }
        p.play({command: 'addToCart', item: p.state.lastId, quantity: number});
        p.play(`Added another ${number} ${p.state.lastName}`);
    } else {
        p.play('Sorry, You should order something first');
    }
});

//11-13
intent(`(remove|delete|exclude) $(ITEM p:items_intent)`,
    `(remove|delete|exclude) $(NUMBER) $(ITEM p:items_intent)`, p => {
        let order = p.visual.order || {};
        let id = items[p.ITEM.value.toLowerCase()];
        if (!order[id]) {
            p.play(`${p.ITEM} has not been ordered yet`);
        } else {
            let quantity = order[id] ? order[id].quantity : 0;
            let deteleQnty = p.NUMBER ? p.NUMBER.number : quantity;

            p.play({command: 'removeFromCart', item: id, quantity: deteleQnty});
            p.play({command: 'navigation', route: '/cart'});

            if (quantity - deteleQnty <= 0) {
                p.play('Removed all ' + p.ITEM);
            } else {
                p.play(`Updated ${p.ITEM} quantity to ${quantity - deteleQnty}`);
            }
        }
    });

// my order
intent(`(my order|my cart|open cart|show cart|show my cart|order details|details)`, p => {
    let order = p.visual.order;
    if (_.isEmpty(order)) {
        p.play("You have not ordered anything.", "Your cart is empty");
        return;
    }
    p.play({command: 'navigation', route: '/cart'});
    p.play("You currently have");
    for (let product in order) {
        const prodObject = order[product];
        let item = project.products.find(i => i.id == prodObject.id);
        p.play({command: 'highlightProducts', value: item.id});
        p.play(prodObject.qty + " " + item.name);
    }
    p.play({command: 'highlightProducts', value: null});
    p.play("in your cart.");
    p.play(`The total amount for your order is: `);
    p.play({command: 'highlight', value: 'total'});
    p.play(`${p.visual.total} dollars`);
    p.play({command: 'highlight', value: null});
    p.play("Do you want to confirm your order?");
    p.then(confirm);
});

intent(`Show $(TYPE ${TYPE_INTENTS})`, `What $(TYPE ${TYPE_INTENTS}) (are available|are for sale)`, p => {
    let type = p.TYPE.toLowerCase();
    let prods = project.products.filter(i => i.type === TYPES[type]);
    if (_.isEmpty(prods)) {
        p.play(`Sorry, we could not find ${type}`);
        return;
    }
    p.play({command: 'navigation', route: '/clothing'});
    p.play({command: 'show_products', items: prods.map(i => i.id)});
    p.play(`From ${type} we offer: `, `We offer several ${type}:`);
    playList(p, prods, "Products", item => item.name, item => item.id, true);
});

intent(`Show $(TYPE ${TYPE_INTENTS}) (under|cheaper than|for less than) $(NUMBER) (dollars|)`,
    `What $(TYPE ${TYPE_INTENTS}) are (under|cheaper than|for less than) $(NUMBER) (dollars|)`, p => {
        let type = p.TYPE.toLowerCase();
        let prods = project.products.filter(i => i.type === TYPES[type] && i.price <= p.NUMBER.number);
        if (_.isEmpty(prods)) {
            p.play(`We could not find ${type} cheaper than ${p.NUMBER.number} dollars`);
            return;
        }
        p.play({command: 'navigation', route: '/clothing'});
        p.play({command: 'show_products', items: prods.map(i => i.id)});
        p.play(`We (offer|have) several ${type} (under|cheaper than|for less than) ${p.NUMBER.number} dollars:`);
        playList(p, prods, "Products", item => item.name, item => item.id, true);
    });

intent(`What is (my|the) total cost`, p => {
    if (_.isEmpty(p.visual.order) || !p.visual.total) {
        p.play(`Your cart is empty`);
        return;
    }
    if (p.visual.screen === 'cart') {
        p.play({command: 'highlight', value: 'total'});
        p.play(`The total amount for your order is: ${p.visual.total} dollars`);
        p.play({command: 'highlight', value: null});
    } else {
        p.play(`The total amount for your order is: ${p.visual.total} dollars`);
    }
});

// checkout
intent(`that's (all|it)`, `(ready to|) checkout`, p => {
    if (_.isEmpty(p.visual.order) || !p.visual.total) {
        p.play("Your cart is empty, please make an order first");
        return;
    }
    p.play({command: 'navigation', route: '/cart'});
    p.play(`The total amount for your order is: `);
    p.play({command: 'highlight', value: 'total'});
    p.play(`${p.visual.total} dollars`);
    p.play({command: 'highlight', value: null});
    p.play("Do you want to confirm your order?");
    p.then(confirm);
});

intent(`finish (order|)`, p => {
    if (_.isEmpty(p.visual.order)) {
        p.play(`Please, add something to your order first`);
    } else {
        p.play({command: "finishOrder"});
        p.play(`Your order has been confirmed, thank you!`);
    }
});

// clear order
intent(`(Clear|Cancel|Remove|Get rid of) (my|) order`,`(Clear|flush|empty) cart`, p => {
    p.play({command: 'clearOrder', route: 'cleared-order'});
    p.play(`Your order has been canceled`);
});

function playList(p, a, command, name, id, readMore = false) {
    let nPlay = a.length <= 4 ? a.length : 3;
    for (let i = 0; i < nPlay; i++) {
        p.play({
            command: 'highlight' + command,
            value: id(a[i])
        });
        p.play(name(a[i]));
    }
    p.play({command: 'highlight' + command, value: null});
    let others = a.length - nPlay;
    if (others > 0) {
        p.play(`and ${others} others`);
        if (readMore) {
            p.play('Do you want to hear more?');
            let state = {items: a, from: 3, step: 3, name: name, type: command, id: id};
            p.then(repeatListItems, {state});
        }
    }
}

function setDataset(p, pDataset) {
    project.items_intent = pDataset.products.map(p => p.name.toLowerCase() + '_').join('|');
    project.items_plural_intent = _.difference(Object.keys(items), pDataset.products.map(p => p.name.toLowerCase())).join('|');
}

function addItems(p, pItems, pNumbers, shift) {
    let answer = "";
    let id, name;
    for (let i = 0; i < pItems.length; i++) {
        id = items[pItems[i].toLowerCase()].id;
        name = pItems[i];
        if (id === undefined) {
            if (!_.isEmpty(answer)) {
                p.play(answer);
            }
            p.play(`Can't find ${pItems[i]} in menu`);
            return;
        } else {
            let number = pNumbers && pNumbers[i - shift] ? pNumbers[i - shift] : 1;
            if (number > 99) {
                p.play(`Sorry, quantity of ${pItems[i]} is too high.`);
                return;
            }
            p.play({command: 'addToCart', item: id, quantity: number});
            answer += i > 0 ? ` and ` : `Added `;
            answer += `${number} ${pItems[i]} `;
        }
    }
    answer += `(to your order|). `;
    p.state.lastId = id;
    p.state.lastName = name;
    if (!p.state.isFullResponseReceived) {
        answer += `Would you like to add more items or checkout?`;
        p.state.isFullResponseReceived = true;
    } else {
        answer += `(Something else?|What else can I do for you?|Do you want to checkout?|Do you need anything else?|)`;
    }
    p.play(answer);
}

// Plural forms impletentation due to https://www.grammarly.com/blog/plural-nouns/
function pluralize(str, bothForms = false) {
    if (_.isEmpty(str))
        return "";
    str = str.toLowerCase();
    let pstr;
    let exceptions = {
        "sheep": "sheep", "series": "series", "species": "species", "deer": "deer",
        "child": "children", "goose": "geese", "man": "men", "woman": "women", "tooth": "teeth",
        "foot": "feet", "mouse": "mice", "person": "people"
    };
    if (exceptions[str]) {
        pstr = exceptions[str];
    } else if (str.endsWith('us')) {
        pstr = str.slice(0, -2) + "i";
    } else if (str.endsWith('is')) {
        pstr = str.slice(0, -2) + "es";
    } else if (str.endsWith('on')) {
        pstr = str.slice(0, -2) + "a";
    } else if (_.any(['s', 'ss', 'sh', 'ch', 'x', 'z'], e => str.endsWith(e))) {
        pstr += "es"
    } else if (_.any(['f', 'fe'], e => str.endsWith(e))) {
        pstr = ['roof', 'belief', 'chef', 'chief'].includes(str) ? str + "s" :
            pstr.slice(0, pstr.lastIndexOf('f')) + "ves";
    } else if (str.slice(-1) === 'y' && !"aeiouy".includes(str.slice(-2, -1))) {
        pstr = str.slice(0, -1) + "ies";
    } else if (str.slice(-1) === 'o') {
        pstr = ['photo', 'piano', 'halo'].includes(str) ? str + "s" : str + "es";
    } else {
        pstr = str + ("aeiouy".includes(str.slice(-1)) ? 's' : 'es');
    }
    return pstr + (bothForms ? '|' + str : '');
}