// Cascading Popup Menus v5.2 - Single Frame Menu example script.


// If you're upgrading from v5.1, you can paste your existing menu data in, and if you're
// upgrading from v5.0 you need to add 'cursor' settings to your ItemStyles.
//
// And before going ANY further, you must have READ and AGREE TO the script license!
// It can be found on my site, in the syntax helpfile, or in the demo script document.


// 'horizontal Bar' style: menu items that use this ItemStyle are 40px wide, have 10px gaps
// between them, no popout indicator (the ">" in some menus) or popout indicator position,
// 0px padding of the text within items, #336699 background colour, a hover colour of #6699CC,
// 'highText' is the stylesheet class used for the menu text both normally and when highlighted,
// no border styles, 'null' means fully opaque items (set them to numbers between 0 and 100 to
// enable semitranslucency), and the 'hand'/'default' cursors are used for linked/submenu items.
var hBar = new ItemStyle(40, 10, '', 0, 0, '15#336699', '10#6699CC', 'highText', 'highText', '', '',
 null, null, 'hand', 'default');

// The 'sub Menu' items: these have popout indicators of "Greater Than" signs ">" 15px from their
// right edge, and CSS borders. Text class also changes on mouseover.
var subM = new ItemStyle(22, 0, '&gt;', -15, 3, '#CCCCDD', '#6699CC', 'lowText', 'highText',
 'itemBorder', 'itemBorder', null, null, 'hand', 'default');

// 'subBlank' is similar, but has an 'off' border the same colour as its background so it
// appears borderless when dim, and 1px spacing between items to show the hover border.
var subBlank = new ItemStyle(22, 1, '&gt;', -15, 3, '#CCCCDD', '#6699CC', 'lowText', 'highText',
 'itemBorderBlank', 'itemBorder', null, null, 'hand', 'default');

// The purplish 'button' style also has 1px spacing to show up the fancy border, and it has
// different colours/text and less padding. They also have translucency set -- these items
// are 80% opaque when dim and 95% when highlighted. It uses the 'crosshair' cursor for items.
var button = new ItemStyle(22, 1, '&gt;', -15, 2, '10#006633', '10#CC6600', 'buttonText', 'buttonHover',
 'buttonBorder', 'buttonBorderOver', 80, 95, 'crosshair', 'default');





// Create a PopupMenu() object, and pass its own name so it can reference itself later on.
// We also use a 'with' block to work with its properties and functions below.

var pMenu = new PopupMenu('pMenu');
with (pMenu)
{

// Here's what the values in the next startMenu() command mean, in order:
//  'root': the name of this menu.
//   false: orientated as a horizontal menu (true creates a vertical menu).
//      10: the 'left' offset of this menu in pixels.
//       0: the 'top' offset of this menu in pixels.
//      17: the height of this menu (for vertical menus, this becomes the menu width).
//    hBar: the ItemStyle used to give this menu colours and layout/formatting.
//      '': this menu does not display within a frame (see the Frameset Example Script to do that).
//   false: this menu shows submenus on mouseover. 'true' means show on click.
//
// Most of the items are 'sm:' items popping out submenus, except the last 'js:' JavaScript command
// to pop open a new window. I've also given each item a length in pixels, overriding the ItemStyle.

startMenu('root', false, 10, 0, 17, hBar, '', false);
addItem('&nbsp; File', 'mFile', 'sm:', null, 40);
addItem('&nbsp; Edit', 'mEdit', 'sm:', null, 40);
addItem('&nbsp; Help', 'mHelp', 'sm:', null, 40);
addItem('&nbsp; Visit My Site', 'window.open("http://www.twinhelix.com")', 'js:', null, 80);


// This is a vertical menu positioned 0px across and 22px down from its trigger, and is 80px wide.
// The URLs are set to # here, be sure to replace them with your path/file names or JS functions!
// Also note how the types are '', indicating these links open in the current frame/window.
// The last item here changes its text on mouseover (^ separates the two strings), links to my site,
// and has a custom ItemStyle and length specified so it's longer than the rest.

startMenu('mFile', true, 0, 22, 80, subM, '', false);
addItem('Open', '#', '');
addItem('Save', '#', '');
addItem('Reopen', 'mReopen', 'sm:');
addItem('SWAP:Check for<br />Update...^Visit<br /><b>TwinHelix</b>',
 'http://www.twinhelix.com', '', subM, 38);

// Here's some more example menus items that address common problems. Try these if you want:
//
// Navigate the whole current window to a page named 'file.html':
//  addItem('Open File', 'file.html', '');
// Open a page in a frame named "content":
//  addItem('Home', '/home/index.html', 'top.content');
// Run a JavaScript command to pop open a new window when clicked:
//  addItem('Catalog', 'window.open("/catalog.html")', 'js:');
// Use a custom ItemStyle you've created:
//  addItem('Text', 'file.html', '', button);
// Make an item 200px long, overriding the default item size:
//  addItem('This contains lots and lots of text', 'file.html', '', null, 200);
// How to open a submenu and also load a file when clicked:
//  with (addItem('Text', 'file.html', '')) sm = 'menuNameHere';
// Popout a submenu named 'mHelp', and give it a JavaScript click action:
//  with(addItem('Help', 'mHelp', 'sm:')) onclick='window.location.href="file.html"';


startMenu('mEdit', true, 0, 22, 80, subM, '', false);
addItem('Cut', '#', '');
addItem('Copy', '#', '');
addItem('Paste', '#', '');
addItem('Convert', 'mConvert', 'sm:');


// This 'mHelp' menu is aligned slightly left of its trigger (-10px).
// Instead of using spaces to indent, consider 'text-indent' in the stylesheet class perhaps?
// The last item is an example of adding extra optional parameters to the addItem() command.
// It uses the subM ItemSyle (regardless of what the rest of this menu uses), is 22px long,
// has 0px spacing after it, and a lesser-than-sign popout indicator positioned 3px from the left
// edge of this item. Note that the parameters after the ItemStyle name are in the same order as
// the ItemStyle command itself, and you can have as many as you want (e.g. background colours).

startMenu('mHelp', true, -10, 22, 80, subM, '', false);
addItem('&nbsp; &nbsp; Contents', '#', '');
addItem('&nbsp; &nbsp; Search', '#', '');
addItem('&nbsp; &nbsp; About', 'mAbout', 'sm:', subM, 22, 0, '&lt;', 3);


// This is 85px across and 0px down... a horizontal popout.
// Again these items have their own ItemStyles, and unique lengths / spacings between specified.

startMenu('mReopen', true, 85, 0, 120, button, '', false);
addItem('Recent Doc 1:<br />Schedule', '#', '', button, 35);
addItem('Recent Doc 2:<br />Cunning Plan', '#', '', button, 35, 5);
addItem('Etc. etc...', '#', '', subM);


// This uses the subBlank ItemStyle which gives the items no borders when dim. The border around
// the whole menu comes from a JavaScript function in the "Menu Effects" section.

startMenu('mConvert', true, 85, 0, 80, subBlank, '', false);
addItem('Windows', '#', '');
addItem('Unix', '#', '');
addItem('Macintosh', '#', '');


// Leftwards popout with a negative x and y relative to its trigger. The item has a custom height.

startMenu('mAbout', true, -85, -18, 80, subM, '', false);
addItem('Leftwards!<br>And up!', '#', '', subM, 40);



// HIDE OR SHOW DELAYS (in milliseconds) can be customised. Defaults are:
//showDelay = 0;
//hideDelay = 500;
// Specify hideDelay as zero if you want to disable autohiding, and showDelay as a couple of
// hundred if you don't want the menus showing instantaneously when moused over.

// HIDE MENUS ON DOCUMENT CLICK: Try uncommenting this, and perhaps set hideDelay to zero:
//hideDocClick = true;

// You can assign 'oncreate' events to specific menus. By default, the script has only one for
// the root menu that shows it when it is created. You may wish to change it to something like the
// following, which uses the animation function to show the menu, or delay its show altogether.
//menu.root[0].oncreate = function() { pMenu.doVis('root', true) }

// End of 'with (pMenu)' block. That's one menu object created!

}





// CREATE ANOTHER MENU OBJECT here if you want multiple menus on a page, or you can just
// duplicate this entire file and rename 'pMenu' to something else.
// Every menu object MUST have a menu named 'root' in it, as that's always visible.

//var anotherMenu = new PopupMenu('anotherMenu');
//with (anotherMenu)
//{
// startMenu('root', .....);
// ... make menus here ...
//}




// ******************** MENU EFFECTS ********************
//
// Now you've created a basic menu object, you can add optional effects like borders and
// shadows to specific menus. You can remove this section entirely if you want, the
// functions called are found at the bottom of this file.



// BORDER: Added to all menus in a named object using a specified ItemStyle. The syntax is:
//  addMenuBorder(menuObject, ItemStyle,
//   opacity of border, 'border colour', border width, 'padding colour', padding width);
// Opacity is a number from 0 to 100, or null for solid colour (just like the ItemStyles).

addMenuBorder(pMenu, window.subBlank,
 null, '#666666', 1, '#CCCCDD', 2);



// DROPSHADOW: added to specific ItemStyles again. The syntax is similar, but later on you
// pass arrays [...] for each layer of the shadow you want. I've used two grey layers
// here, but you can use as many or as few as you want. The syntax for the layers is:
//  [opacity, 'layer colour', X offset, Y offset, Width Difference, Height difference]
// Opacity is from 0 to 100 (or null to make it solid), and the X/Y offsets are the
// distance in pixels from the menu's top left corner to that shadow layer's corner.
// The width/height differences are added or subtracted to the current menu size, for
// instance the first layer of this shadow is 4px narrower and shorter than the menu
// it is shadowing.

addDropShadow(pMenu, window.subM,
 [40,"#333333",6,6,-4,-4], [40,"#666666",4,4,0,0]);
addDropShadow(pMenu, window.subBlank,
 [40,"#333333",6,6,-4,-4], [40,"#666666",4,4,0,0]);



// ANIMATION SETTING: We add this to the 'pMenu' menu object for supported browsers.
// IE4/Mac and Opera 5/6 don't support clipping, and Mozilla versions prior to 1.x (such as
// Netscape 6) are too slow to support it, so I'm doing some browser sniffing.
// If you don't want animation, delete this entirely, and the menus will act normally.
// Change the speed if you want... it's the last number, between -100 and 100, and is
// defined as the percentage the animation moves each frame (defaults are 10 and 15).

if ((navigator.userAgent.indexOf('rv:0.')==-1) &&
    !(isOp&&!document.documentElement) && !(isIE4&&!window.external))
{
 pMenu.showMenu = new Function('mN','menuAnim(this, mN, 10)');
 pMenu.hideMenu = new Function('mN','menuAnim(this, mN, -15)');

 // Add animation to other menu objects like this...
 //anotherMenu.showMenu = new Function('mN','menuAnim(this, mN, 10)');
 //anotherMenu.hideMenu = new Function('mN','menuAnim(this, mN, -15)');
}







// ******************** FUNCTIONS CALLED BY THE EFFECTS SECTION ********************

// These can be deleted if you're not using them. Alternatively, if you're using several menu
// data files, you may want to move them to the "core" script file instead.



// This is the "positioning from page anchors" code used by the advanced positioning expressions.
page.elmPos=function(e,p)
{
 var x=0,y=0,w=p?p:this.win;
 e=e?(e.substr?(isNS4?w.document.anchors[e]:getRef(e,w)):e):p;
 if(isNS4){if(e&&(e!=p)){x=e.x;y=e.y};if(p){x+=p.pageX;y+=p.pageY}}
 if (e && this.MS && navigator.platform.indexOf('Mac')>-1 && e.tagName=='A')
 {
  e.onfocus = new Function('with(event){self.tmpX=clientX-offsetX;' +
   'self.tmpY=clientY-offsetY}');
  e.focus();x=tmpX;y=tmpY;e.blur()
 }
 else while(e){x+=e.offsetLeft;y+=e.offsetTop;e=e.offsetParent}
 return{x:x,y:y};
};




// Animation:
//
// Each menu object you create by default shows and hides its menus instantaneously.
// However you can override this behaviour with custom show/hide animation routines,
// as we have done in the "Menu Effects" section. Feel free to edit this, or delete
// this entire function if you're not using it. Basically, make functions to handle
// menuObj.showAnim() and .hideAnim(), both of which are passed menu names.
//
// Customisers: My lyr.clip() command gets passed the parameters (x1, y1, x2, y2)
// so you might want to adjust the direction etc. Oh, and I'm adding 2 to the dimensions
// to be safe due to different box models in some browsers.
// Another idea: add some if/thens to test for specific menu names...?

function menuAnim(menuObj, menuName, dir)
{
 // The array index of the named menu (e.g. 'mFile') in the menu object (e.g. 'pMenu').
 var mD = menuObj.menu[menuName][0];
 // Add timer and counter variables to the menu data structure, we'll need them.
 if (!mD.timer) mD.timer = 0;
 if (!mD.counter) mD.counter = 0;

 with (mD)
 {
  // Stop any existing animation.
  clearTimeout(timer);

  // If the litNow() array doesn't show this menu as lit, and we're still showing it,
  // force a quick hide (this stops miscellaneous timer errors).
  //if (dir>0 && !menuObj.litNow[menuObj.menu[menuName][0].parentMenu]) dir = -100;

  // If the layer doesn't exist (cross-frame navigation) quit.
  if (!lyr || !lyr.ref) return;
  // This next line is not strictly necessary, but it stops the one-in-a-hundred menu that
  // shows and doesn't hide on very quick mouseovers.
  if (!visNow && dir>0) dir = 0-dir;
  // Show the menu if that's what we're doing.
  if (dir>0) lyr.vis('visible');
  // Also raise showing layers above hiding ones.
  lyr.sty.zIndex = dir>0 ? mD.zIndex + 1 : 1001;

  // Alpha fade in IE5.5+. Mozilla's opacity (pre-v1.7) isn't well suited as it's an inheritable
  // property rather than a block-level filter, and it's slow, but uncomment and try it perhaps.
  // WARNING: This looks funny if you're mixing opaque and translucent items e.g. solid menus
  // with dropshadows. If you're going to use it, either disable dropshadows or set the opacity
  // values for your items to numbers instead of null.
  //if (isIE && window.createPopup) lyr.alpha(counter&&(counter<100) ? counter : null);

  // Clip the visible area. The syntax is:   lyr.clip(left, top, right, bottom);
  // As you can see in these examples, three are static at either zero or the edge of a menu item,
  // and either the top or bottom is a complicated formula based on the 'counter' variable which
  // counts from 0 to 100 and back again; this give a nice accelerating-sliding animation.
  // Feel free to experiment with your own animations, here are some samples (use one only):

  // Straightforward downwards clipping animation (default setting):
  lyr.clip(0, 0, menuW+2, (menuH+2)*Math.pow(Math.sin(Math.PI*counter/200),0.75) );
  // If you want, comment out the above line and enable this one to animate bottom-upwards:
  //lyr.clip(0, (menuH+2)-(menuH+2)*Math.pow(Math.sin(Math.PI*counter/200),0.75), menuW+2, menuH+2);
  // Another alternative: Move+clip sliding animation. Looks really cool :).
  //if (!counter) mD.origY = lyr.y();
  //var newY = (menuH+2)-(menuH+2)*Math.pow(Math.sin(Math.PI*counter/200),0.75);
  //lyr.clip(0, newY, menuW+2, menuH+2);
  //lyr.y(mD.origY - newY);

  // Increment the counter and if it hasn't reached the end (counter is 0% or 100%),
  // set the timer to call the animation function again in 40ms to contine the animation.
  // Note that we hide the menu div on animation end in that direction.
  counter += dir;
  if (counter>100) { counter = 100; lyr.sty.zIndex = mD.zIndex }
  else if (counter<0) { counter = 0; lyr.vis('hidden') }
  else timer = setTimeout('menuAnim('+menuObj.myName+',"'+menuName+'",'+dir+')', 40);
 }
};




// Borders and Dropshadows:
//
// Here's the menu border and dropshadow functions we call above. Edit ot delete if you're
// not using them. Basically, they assign a string to pMenu.menu.menuName[0].extraHTML, which
// is written to the document with the menus as they are created -- the string can contain
// anything you want, really. They also adjust the menu dimensions and item positions
// to suit. Dig out the Object Browser script and open up "pMenu" for more info.

function addMenuBorder(mObj, iS, alpha, bordCol, bordW, backCol, backW)
{
 // Loop through the menu array of that object, finding matching ItemStyles.
 for (var mN in mObj.menu)
 {
  var mR=mObj.menu[mN], dS='<div style="position:absolute; background:';
  if (mR[0].itemSty != iS) continue;
  // Loop through the items in that menu, move them down and to the right a bit.
  for (var mI=1; mI<mR.length; mI++)
  {
   mR[mI].iX += bordW+backW;
   mR[mI].iY += bordW+backW;
  }
  // Extend the total dimensions of menu accordingly.
  mW = mR[0].menuW += 2*(bordW+backW);
  mH = mR[0].menuH += 2*(bordW+backW);

  // Set the menu's extra content string with divs/layers underneath the items.
  if (isNS4) mR[0].extraHTML += '<layer bgcolor="'+bordCol+'" left="0" top="0" width="'+mW+
   '" height="'+mH+'" z-index="980"><layer bgcolor="'+backCol+'" left="'+bordW+'" top="'+
   bordW+'" width="'+(mW-2*bordW)+'" height="'+(mH-2*bordW)+'" z-index="990"></layer></layer>';
  else mR[0].extraHTML += dS+bordCol+'; left:0px; top:0px; width:'+mW+'px; height:'+mH+
   'px; z-index:980; '+
   (alpha!=null?'filter:alpha(opacity='+alpha+'); -moz-opacity:'+alpha+'%; opacity:'+(alpha/100):'')+
   '">'+dS+backCol+'; left:'+bordW+'px; top:'+bordW+'px; width:'+(mW-2*bordW)+'px; height:'+
   (mH-2*bordW)+'px; z-index:990"></div></div>';
 }
};

function addDropShadow(mObj, iS)
{
 // Pretty similar to the one above, just loops through list of extra parameters making
 // dropshadow layers (from arrays) and extending the menu dimensions to suit.
 for (var mN in mObj.menu)
 {
  var a=arguments, mD=mObj.menu[mN][0], addW=addH=0;
  if (mD.itemSty != iS) continue;
  for (var shad=2; shad<a.length; shad++)
  {
   var s = a[shad];
   // Safari 1.2 bug: it inherits alpha values SIDEWAYS!?!? What were they thinking?
   var alpha = (s[0]!=null && navigator.userAgent.indexOf('AppleWebKit') == -1);
   if (isNS4) mD.extraHTML += '<layer bgcolor="'+s[1]+'" left="'+s[2]+'" top="'+s[3]+'" width="'+
    (mD.menuW+s[4])+'" height="'+(mD.menuH+s[5])+'" z-index="'+(arguments.length-shad)+'"></layer>';
   else mD.extraHTML += '<div style="position:absolute; background:'+s[1]+'; left:'+s[2]+
    'px; top:'+s[3]+'px; width:'+(mD.menuW+s[4])+'px; height:'+(mD.menuH+s[5])+'px; z-index:'+
    (a.length-shad)+'; '+
    (alpha?'filter:alpha(opacity='+s[0]+'); -moz-opacity:'+s[0]+'%; opacity:'+(s[0]/100):'')+
    '"></div>';
   addW=Math.max(addW, s[2]+s[4]);
   addH=Math.max(addH, s[3]+s[5]);
  }
  mD.menuW+=addW; mD.menuH+=addH;
 }
};