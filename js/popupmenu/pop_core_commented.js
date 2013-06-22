/*

CASCADING POPUP MENUS v5.2 RC (c) 2001-2006 Angus Turnbull, http://www.twinhelix.com
Altering this notice or redistributing this file is prohibited.

*/


// This is the full, commented script file, to use for reference purposes or if you feel
// like tweaking anything. I used the "CodeTrimmer" utility availble from my site
// (under 'Miscellaneous' scripts) to trim the comments out of this JS file.



// *** COMMON CROSS-BROWSER COMPATIBILITY CODE ***


// This is taken from the "Modular Layer API" available on my site.
// See that for the readme if you are extending this part of the script.

var isDOM=document.getElementById?1:0,
 isIE=document.all?1:0,
 isNS4=navigator.appName=='Netscape'&&!isDOM?1:0,
 isIE4=isIE&&!isDOM?1:0,
 isOp=self.opera?1:0,
 isDyn=isDOM||isIE||isNS4;

function getRef(i, p)
{
 p=!p?document:p.navigator?p.document:p;
 return isIE ? p.all[i] :
  isDOM ? (p.getElementById?p:p.ownerDocument).getElementById(i) :
  isNS4 ? p.layers[i] : null;
};

function getSty(i, p)
{
 var r=getRef(i, p);
 return r?isNS4?r:r.style:null;
};

if (!self.LayerObj) var LayerObj = new Function('i', 'p',
 'this.ref=getRef(i, p); this.sty=getSty(i, p); return this');
function getLyr(i, p) { return new LayerObj(i, p) };

function LyrFn(n, f)
{
 LayerObj.prototype[n] = new Function('var a=arguments,p=a[0],px=isNS4||isOp?0:"px"; ' +
  'with (this) { '+f+' }');
};
LyrFn('x','if (!isNaN(p)) sty.left=p+px; else return parseInt(sty.left)');
LyrFn('y','if (!isNaN(p)) sty.top=p+px; else return parseInt(sty.top)');
LyrFn('vis','sty.visibility=p');
LyrFn('bgColor','if (isNS4) sty.bgColor=p?p:null; ' +
 'else sty.background=p?p:"transparent"');
LyrFn('bgImage','if (isNS4) sty.background.src=p?p:null; ' +
 'else sty.background=p?"url("+p+")":"transparent"');
LyrFn('clip','if (isNS4) with(sty.clip){left=a[0];top=a[1];right=a[2];bottom=a[3]} ' +
 'else sty.clip="rect("+a[1]+"px "+a[2]+"px "+a[3]+"px "+a[0]+"px)" ');
LyrFn('write','if (isNS4) with (ref.document){write(p);close()} else ref.innerHTML=p');
LyrFn('alpha','var f=ref.filters,d=(p==null),o=d?"inherit":p/100; if (f) {' +
 'if (!d&&sty.filter.indexOf("alpha")==-1) sty.filter+=" alpha(opacity="+p+")"; ' +
 'else if (f.length&&f.alpha) with(f.alpha){if(d)enabled=false;else{opacity=p;enabled=true}} }' +
 'else if (isDOM)sty.opacity=sty.MozOpacity=o');

function setLyr(v, dw, p)
{
 if (!setLyr.seq) setLyr.seq=0;
 if (!dw) dw=0;
 var o = !p ? isNS4?self:document.body : !isNS4&&p.navigator?p.document.body:p,
  IA='insertAdjacentHTML', AC='appendChild', id='_sl_'+setLyr.seq++;

 if (o[IA]) o[IA]('beforeEnd', '<div id="'+id+'" style="position:absolute"></div>');
 else if (o[AC])
 {
  var n=document.createElement('div');
  o[AC](n); n.id=id; n.style.position='absolute';
 }
 else if (isNS4)
 {
  var n=new Layer(dw, o);
  id=n.id;
 }

 var l=getLyr(id, p);
 with (l) if (ref) { vis(v); x(0); y(0); sty.width=dw+(isNS4?0:'px') }
 return l;
};

if (!self.page) var page = { win:self, minW:0, minH:0, MS:isIE&&!isOp };

page.db = function(p) { with (this.win.document) return (isDOM?documentElement[p]:0)||body[p]||0 };

page.winW=function() { with (this) return Math.max(minW, MS ? db('clientWidth') : win.innerWidth) };
page.winH=function() { with (this) return Math.max(minH, MS ? db('clientHeight') : win.innerHeight) };

page.scrollX=function() { with (this) return MS ? db('scrollLeft') : win.pageXOffset };
page.scrollY=function() { with (this) return MS ? db('scrollTop') : win.pageYOffset };







// *** POPUP MENU MAIN OBJECT CONSTRUCTOR ***


// This takes arrays of data and names and assigns the values to a specified object.
function addProps(obj, data, names, addNull)
{
 for (var i = 0; i < names.length; i++) if(i < data.length || addNull) obj[names[i]] = data[i];
};


// Pass the name of the menu object being created, e.g. var abc = new PopupMenu('abc');
function PopupMenu(myName)
{
 this.myName = myName;

 // Manage what gets lit and shown when. Override these on a per-menu-object basis.
 this.showTimer = this.hideTimer = this.showDelay = 0;
 this.hideDelay = 500;

 // 'menu': the main data store, contains subarrays for each menu e.g. pMenu.menu['root'][];
 this.menu = {};
 // litNow and litOld arrays control what items get lit in the hierarchy.
 // For instance, litNow['root'] will return the item number lit in that menu.
 this.litNow = {};
 this.litOld = {};

 // The item the mouse is currently over. Used by click processor to help NS4.
 this.overM = '';
 this.overI = 0;
 // Hide menus on document click? Off by default.
 this.hideDocClick = 0;

 // The active menu, to which addItem() will assign its results.
 this.actMenu = null;

 // Every time we declare a new PopupMenu(), add it to our internal list.
 PopupMenu.list[myName] = this;
};

// The internal list of popup menu objects created.
PopupMenu.list = {};

// A quick reference to save a few bytes :).
var PmPt = PopupMenu.prototype;





// Called by the other mouse event functions, this runs the menu-wide and per-item
// onmouseover/out/click events and returns their return values.
PmPt.callEvt = function(mN, iN, evt)
{
 var i = this.menu[mN][iN], r1 = this[evt] ? this[evt](mN, iN) : 0, r2;
 if (i[evt])
 {
  if (i[evt].substr) i[evt] = new Function('mN', 'iN', i[evt]);
  r2 = i[evt](mN, iN);
 }
 return typeof r2 == 'boolean' ? r2 : r1;
};


// *** MOUSE EVENT CONTROL FUNCTIONS ***


// Most of these are passed the relevant 'menu Name' and 'item Number' from page events.
// The 'with (this)' means it uses the properties and functions of the current menu object.
PmPt.over = function(mN, iN) { with (this)
{
 // Cancel any pending menu hides from a previous mouseout.
 clearTimeout(hideTimer);
 // Set the object-global 'over' variables to point to this item.
 overM = mN;
 overI = iN;

 // Call the 'onmouseover' events for the menu and this item.
 // 'evtRtn' is checked later and no menus shown if set.
 var evtRtn = iN ? callEvt(mN, iN, 'onmouseover') : 0, rtn = evtRtn||false;


 // Remember what was lit last time, and compute a new hierarchy.
 litOld = litNow;
 litNow = {};
 var litM = mN, litI = iN;
 // Loop and keep adding the currently lit item number to our associative array.
 if (mN) do
 {
  litNow[litM] = litI;
  // These will become undefined at the top of the hierarchy, stopping the loop.
  // (Remember that root menus doesn't have a parent).
  litI = menu[litM][0].parentItem;
  litM = menu[litM][0].parentMenu;
 } while (litM);


 // If the two arrays are the same, return... no use hiding/lighting otherwise.
 // This stops unnecessary operations as mouse events will bubble and fire several times.
 var same = 1;
 for (var z in menu) same &= (litNow[z] == litOld[z]);
 if (same) return rtn;


 // Otherwise, if this is a different item being moused over, clear any pending shows.
 clearTimeout(showTimer);

 // Cycle through menu array, lighting and hiding menus as necessary.
 for (var thisM in menu) with (menu[thisM][0])
 {
  // Menu layer doesn't exist yet (or frame has navigated)? Keep rollin'...
  if (!lyr) continue;

  // The 'new Item' and 'old Item' in this menu that are lit.
  lI = litNow[thisM];
  oI = litOld[thisM];

  // If an item is lit now and wasn't before, highlight it,
  // and if another item was lit but isn't now, dim it.
  if (lI != oI)
  {
   if (lI) changeCol(thisM, lI);
   if (oI) changeCol(thisM, oI);
  }

  // Clear the "show onclick submenus" flag of that menu if nothing's highlighted.
  if (!lI) clickDone = 0;

  // Don't manipulate visibilities for 'root'-type menus -- continue loop.
  if (isRoot) continue;

  // Otherwise, make sure if it's lit, it's shown, and if it's unlit, it's hidden.
  // We call the doVis() function of the menu object, with a name and boolean value.
  // It handles the positioning and visibility side of things.
  if (lI && !visNow) doVis(thisM, 1);
  if (!lI && visNow) doVis(thisM, 0);
 }

 // Get target menu to show for 'sm:' items - if we've got one, position & show it.
 nextMenu = '';
 // Only do this if onmouseover() didn't "return false" (via the return value 'evtRtn').
 if (menu[mN] && menu[mN][iN].sm && (evtRtn+'' != 'false'))
 {
  // The target menuname, and the layer object of the current menu container.
  var m = menu[mN], t=m[iN].sm;

  // No target menu?
  if (!menu[t]) return rtn;

// DYNAMIC MENU CREATION SUPPORT - Uncomment these next lines to enable it.
// This creates only the root menu on page load, and others when you point at them.
// You'll also have to edit the commented "Events" file to make it work.

//if (!menu[t][0].lyr) update(false, t);
//if (!menu[t][0].lyr) return 0;

  // If the target menu is set to show submenus on click, and it hasn't been recently
  // clicked, don't do any onmouseover actions!
  if (m[0].clickSubs && !m[0].clickDone) return rtn;

  // Either position/show immediately or after a delay, via the doVis() function.
  // Set nextMenu to the impending show, so the popOut() function knows when not to cancel it.
  nextMenu = t;
  if (showDelay) showTimer = setTimeout(myName+'.doVis("'+t+'", 1)', showDelay);
  else doVis(t, 1);
 }

 // Return the value from our event handlers, so that "return true" onmouseover settings work.
 return rtn;
}};


// Handles onmouseout events, same parameters. Sets a timeout to another over() to hide menus.
PmPt.out = function(mN, iN) { with (this)
{
 // Sometimes, across frames, overs and outs can get confused.
 // So, return if we're exiting an item we have yet to enter...
 if (mN!=overM || iN!=overI) return;

 // thisI = A quick reference to this item.
 // Run both global and per-item onmouseout events, if any are set. Check for cancels.
 var thisI = menu[mN][iN], evtRtn = iN ? callEvt(mN, iN, 'onmouseout') : 0;

 // Stop showing a submenu from this level if this item isn't pointing to the same one.
 if (thisI.sm != nextMenu)
 {
  clearTimeout(showTimer);
  nextMenu = '';
 }

 // Dim/hide all menus rapidly (if it's a root menu item without a popout) or as specified.
 // Remember that the timeout is cancelled by another instance of the over function.
 // Calling 'over("", 0)' hides all menus but the root menu(s), and highlights no items.
 // If hideDelay equals zero (or onmouseout() returns false) the menus are never hidden.
 if (hideDelay && (evtRtn+'' != 'false'))
 {
  var delay = menu[mN][0].isRoot && !thisI.sm ? 50 : hideDelay;
  hideTimer = setTimeout(myName + '.over("", 0)', delay);
 }

 // Clear the 'over' variables.
 overM = '';
 overI = 0;
}};


// Called onclick with menu & item. Handles frame/file navigation or special items.
PmPt.click = function(mN, iN) { with (this)
{
 // A reference to this menu, the event handler's return value, and a 'hide menu?' flag.
 var m = menu[mN], evtRtn = callEvt(mN, iN, 'onclick'), hm = 1;

 // Did the event handler 'return false'? If so, we're out of here too.
 if (evtRtn+'' == 'false') return false;

 // Otherwise, decide what to do based on the type of the item.
 // * Targeting another popout: Either activate show-on-click or skip to the end.
 //   Also record this menu as actively clicked so click-submenus show.
 // * A JavaScript function: eval() it and nothing else.
 // * File link: navigate the correct window then hide menus.
 with (m[iN])
 {
  if (type == 'js:') eval(href);
  else
  {
   if (sm && m[0].clickSubs)
   {
    m[0].clickDone = 1;
    doVis(sm, 1);
    hm = 0;
   }
   if (href)
   {
    type = type || 'window';
    eval(type + '.location.href="' + href + '"');
   }
  }
 }

 // Unless this is show-on-click, we hide all menus by calling over() with no menuname.
 if (hm) over('', 0);
 // Return either a returned value, or false if none specified.
 return evtRtn||false;
}};


// Called by the over() function, this will highlight or dim individual items.
// It will call itself repeatedly for colour fading items.
// Last 'fc' parameter indicates a fading background colour loop, called by a timeout.
PmPt.changeCol = function(mN, iN, fc) { with (this.menu[mN][iN])
{
 // Quit for uncreated/unreferenced items, we can't change their colours!
 if (!lyr || !lyr.ref) return;

 // Decide whether this item has a background image (outCol contains a period?).
 // Set it to 0 if our colours are the same, so we don't change the value.
 var bgFn = outCol!=overCol ? (outCol.indexOf('.')==-1 ? 'bgColor' : 'bgImage') : 0;
 // Are we highlighting/dimming the item, and do we do text/alpha effects (doFX)?
 // We don't do text/alpha effects if the lit item isn't changing, or we're fading.
 var ovr = (this.litNow[mN]==iN)?1:0, doFX = (!fc && this.litNow[mN]!=this.litOld[mN]);
 // The default colour for non-fading items, set to over or out colour.
 var col = ovr ? overCol : outCol;

 // If this item has a colour fade set, do the math...
 if (fade[0])
 {
  // Clear the existing timer, and reset our colour for calculated hex digits.
  clearTimeout(timer);
  col = '#';

  // Increment the fading counter in the proper direction and speed (fade[ovr][1]).
  count = Math.max(0, Math.min(count+(2*ovr-1)*parseInt(fade[ovr][0]), 100));

  // Since Konqueror as of v3.1 doesn't support Number.toString(radix), we need a hack.
  // What the heck were they thinking/smoking when they omitted that? :P
  var oc, nc, hexD = '0123456789ABCDEF';

  // Loop through remaining fade[], to calculate 3 new hex pairs (0xRR, 0xGG and 0xBB).
  for (var i=1; i<4; i++)
  {
   // Make a new hex pair based on weighted averages of the out/over array indices.
   oc = parseInt('0x'+fade[0][i]);
   nc = parseInt(oc + (parseInt('0x'+fade[1][i])-oc)*(count/100));
   col += hexD.charAt(Math.floor(nc/16)).toString() + hexD.charAt(nc%16);
  }

  // Set a timer to call this function again later if it's not at the start or end.
  // Pass the 'fc' parameter to indicate not to do alpha/text/border swaps.
  if (count%100 > 0) timer = setTimeout(this.myName+'.changeCol("'+mN+'",'+iN+',1)', 50);
 }


 // Regular colour change: do before text/border change due to Netscape 4 bugs.
 if (bgFn && isNS4) lyr[bgFn](col);

 // Test for CSS text/border style changes, we can skip them if not needed.
 // In Netscape 4, rewrite layer contents if required (causes a little flickering)...
 // Otherwise manipulate the DOM tree for IE/NS6+ (faster than rewriting contents).
 // We always rewrite if text/indicator changes are specified, of course.
 var reCSS = (overClass!=outClass || outBorder!=overBorder);
 if (doFX) with (lyr)
 {
  if (!this.noRW && (overText || overInd || isNS4&&reCSS)) write(this.getHTML(mN, iN, ovr));
  if (!isNS4 && reCSS)
  {
   ref.className = (ovr ? overBorder : outBorder);
   var chl = (isDOM ? ref.childNodes : ref.children);
   if (chl && !overText) for (var i = 0; i < chl.length; i++)
    chl[i].className = ovr?overClass:outClass;
  }
 }

 // ...and some other browsers have bugs unless the colour change is AFTER the border.
 if (bgFn && !isNS4) lyr[bgFn](col);

 // Alpha filtering activated? Might as well set that then too...
 // Weirdly it has to be done after the border change, another random Mozilla bug...
 if (doFX && outAlpha!=overAlpha) lyr.alpha(ovr ? overAlpha : outAlpha);
}};


// The position() function is passed either a menuname to position that menu, or nothing
// to reposition all menus. It's called internally before menus are shown, and by the events
// section of the code to reposition menus after window scrolling and resizing.
PmPt.position = function(posMN) { with (this)
{
 for (mN in menu) if (!posMN || posMN==mN) with (menu[mN][0])
 {
  // If the menu hasn't been created or is not set to be visible, loop.
  if (!lyr || !lyr.ref || !visNow) continue;

  // Set up some variables and the initial calculated positions.
  var pM, pI, newX = eval(offX), newY = eval(offY);

  // Find its parent menu references, if it is not a 'root' class menu.
  if (!isRoot)
  {
   pM = menu[parentMenu];
   pI = pM[parentItem].lyr;
   // Having no parent item is a bad thing, especially in cross-frame code.
   if (!pI) continue;
  }

  // Find parent window for correct page object, or this window if not.
  var eP = eval(par), pW = (eP&&eP.navigator ? eP : window);

  // Find proper numerical values for the current window position + edges, so menus
  // don't make a beeline for the upper-left corner of the page. Set window dimensions
  // to 9999px if they can't be found.
  with (pW.page) var sX=scrollX(), wX=sX+winW()||9999, sY=scrollY(), wY=winH()+sY||9999;

  // Relatively positioned submenus? Add parent menu/item position & check screen edges.
  // Subtract either 5px or 20px at the end to allow for padding and NS scrollbars.
  var sb = page.MS?5:20;
  if (pM && typeof(offX)=='number') newX = Math.max(sX,
   Math.min(newX+pM[0].lyr.x()+pI.x(), wX-menuW-sb));
  if (pM && typeof(offY)=='number') newY = Math.max(sY,
   Math.min(newY+pM[0].lyr.y()+pI.y(), wY-menuH-sb));

  // Assign the final calculated positions.
  lyr.x(newX);
  lyr.y(newY);
 }
}};


// Default show/hide function, pass a menu name and true/false visibility setting to it.
// They either call the animation functions, or just plain show/hide the menu.
PmPt.doVis = function(mN, show) { with (this)
{
 // References -- mA is to a possible menu animation function name.
 var m = menu[mN], sh = (show?'show':'hide'), mA = sh+'Menu', mE = 'on'+sh;
 // Record the visibility state of this menu, whatever happens.
 m[0].visNow = show;
 // Watch for users who pass wrong menunames to addItem commands, or cross-frame menus...
 if (m && m[0].lyr && m[0].lyr.ref)
 {
  if (show) position(mN);
  // Set the Z-Index of this menu to slightly more than its parent menu.
  var p = m[0].parentMenu;
  if (p) m[0].lyr.sty.zIndex = m[0].zIndex = menu[p][0].zIndex + 2;
  // Call onshow and onhide events.
  if (this[mE]) this[mE](mN);
  // Either call the animation function or just show/hide it ourselves.
  if (this[mA]) this[mA](mN);
  else m[0].lyr.vis(show?'visible':'hidden');
 }
}};





// *** MENU OBJECT CONSTRUCTION FUNCTIONS ***

function ItemStyle()
{
 // Like the other constructors, this passes a list of property names that correspond to the list
 // of arguments.
 var names = ['len', 'spacing', 'popInd', 'popPos', 'pad', 'outCol', 'overCol', 'outClass',
  'overClass', 'outBorder', 'overBorder', 'outAlpha', 'overAlpha', 'normCursor', 'nullCursor'];
 addProps(this, arguments, names, 1);
};

PmPt.startMenu = function(mName) { with (this)
{
 // Create a new array within the menu object if none exists already, and a new menu object within.
 if (!menu[mName]) menu[mName] = [{}];

 // Clean out existing items in this menu in case of a menu update.
 // actMenu is a reference to this menu for addItem() function later, while the local variable
 // aM is a quick reference to the current menu descriptor -- array index 0, 1+ are items.
 actMenu = menu[mName];
 aM = actMenu[0];
 actMenu.length = 1;

 // Not all of these are actually passed to the constructor -- the last few are null.
 var names = ['name', 'isVert', 'offX','offY', 'width', 'itemSty', 'par', 'clickSubs',
  'clickDone', 'visNow', 'parentMenu', 'parentItem', 'oncreate', 'isRoot'];
 addProps(aM, arguments, names, 1);

 // extraHTML is a string added to menu layers for things like dropshadows, backgrounds etc.
 aM.extraHTML = '';
 // Set the menu dimensions to zero initially. Also these are used to position items.
 aM.menuW = aM.menuH = 0;
 // The default menu z-index.
 aM.zIndex = 1000;

 // Reuse old layers if we can, no use creating new ones every time the menus refresh.
 if (!aM.lyr) aM.lyr = null;

 // Set the flag for 'root 'menus and set an oncreate event to show them initially.
 // oncreate is passed a reference to the main PopupMenu object.
 if (mName.substring(0, 4) == 'root')
 {
  aM.isRoot = 1;
  aM.oncreate = new Function('obj', 'this.visNow=1; obj.position("' + mName + '"); ' +
   'this.lyr.vis("visible")');
 }

 // Return a reference to this menu data array entry for tweaking.
 return aM;
}};


PmPt.addItem = function() { with (this) with (actMenu[0])
{
 // 'with' the current menu object and active menu descriptor object from startMenu().

 // Add these properties onto a new 'active Item' at the end of the active menu.
 var aI = actMenu[actMenu.length] = {};

 // Add function parameters to object. Again, most will be undefined, set later.
 var names = ['text', 'href', 'type', 'itemSty', 'len', 'spacing', 'popInd', 'popPos',
  'pad', 'outCol', 'overCol', 'outClass', 'overClass', 'outBorder', 'overBorder',
  'outAlpha', 'overAlpha', 'normCursor', 'nullCursor',
  'iX', 'iY', 'iW', 'iH', 'fW', 'fH', 'overText', 'overInd', 'sm', 'lyr',
  'onclick', 'onmouseover', 'onmouseout'];
 addProps(aI, arguments, names, 1);

 // Find an applicable itemSty -- either passed to this item or the menu[0] object.
 var iSty = arguments[3] ? arguments[3] : actMenu[0].itemSty;
 // Loop through its properties, add them if they don't already exist (overridden e.g. length).
 for (prop in iSty) if (aI[prop]+'' == 'undefined') aI[prop] = iSty[prop];

 // For 'sm:' items, set the 'sm' property and clear the 'href'.
 if (aI.type == 'sm:') { aI.sm = aI.href; aI.href = '' }

 // Regular expression for swapping text and popout indicator on mouseover.
 // Alias r to RegExp to save space, as Konq 3 has some problems using 'with (RegExp)'.
 var r = RegExp, re = /^SWAP:(.*)\^(.*)$/;
 // Split text and/or indicator to over and out properties if required.
 if (aI.text.match(re)) { aI.text = r.$1; aI.overText = r.$2 }
 if (aI.popInd.match(re)) { aI.popInd = r.$1; aI.overInd = r.$2 }

 // For the colour fading, pull properties out of the nn#RRGGBB format colours.
 aI.timer = aI.count = 0;
 aI.fade = [];
 for (var i = 0; i < 2; i++)
 {
  // Set oC to the name of the property to check, either 'outCol' or 'overCol'.
  var oC = i ? 'overCol' : 'outCol';
  // The ItemStyle 'nn#RRGGBB' fading speed format: use a regex to match it.
  if (aI[oC].match(/^(\d+)\#(..)(..)(..)$/))
  {
   // Reset the outCol and overCol values to normal for the div-writing routines.
   aI[oC] = '#' + r.$2 + r.$3 + r.$4;
   // Then store a subarray of fade speed and 3 hex colour calues if detected.
   aI.fade[i] = [r.$1, r.$2, r.$3, r.$4];
  }
 }

 // In NS4, since borders are assigned to the contents rather than the layer, increase padding.
 if (aI.outBorder && isNS4) aI.pad++;

 // Non-IE browsers use a different cursor name for the 'hand' cursor.
 // I'm aware that 'pointer' is the W3C standard, I just prefer 'hand' by default :).
 if (!isIE)
 {
  if (aI.normCursor=='hand') aI.normCursor = 'pointer';
  if (aI.nullCursor=='hand') aI.nullCursor = 'pointer';
 }

 // The actual dimensions of the items, store here as properties so they can be accessed later.
 aI.iW = isVert ? width : aI.len;
 aI.iH = isVert ? aI.len : width;

 // The spacing of the previous menu item in this menu, if relevant.
 var lastGap = actMenu.length > 2 ? actMenu[actMenu.length - 2].spacing : 0;

 // 'spc' is the amount we subtract from this item's position so borders overlap a little.
 // Of course we don't do it to the first item.
 var spc = aI.outBorder && actMenu.length > 2 ? 1 : 0;

 // We position this item at the end of the current menu's dimensions,
 // and then increase the menu dimensions by the size of this item.
 if (isVert)
 {
  menuH += lastGap - spc;
  aI.iX = 0; aI.iY = menuH;
  menuW = width; menuH += aI.iH;
 }
 else
 {
  menuW += lastGap - spc;
  aI.iX = menuW; aI.iY = 0;
  menuW += aI.iW; menuH = width;
 }

 // Return the reference so we can tweak the item ourselves :).
 return aI;
}};



// *** MAIN MENU HTML CREATION/UPDATE FUNCTIONS ***


// Returns the inner HTML of an item, used for menu generation, and highlights in NS4.
// (In these functions, just call alert() if you want to figure out what's being created :).
PmPt.getHTML = function(mN, iN, isOver) { with (this)
{
 var itemStr = '';
 with (menu[mN][iN])
 {
  // Retrieve the appropriate values for the CSS "text Class", "text" and "popout Indicator".
  // Also pre-compose a little common item text; including a link tag with the filename as the
  // HREF will help tabbed browsers a lot.
  var tC = isOver?overClass:outClass,
   txt = isOver&&overText?overText:text,
   popI = isOver&&overInd?overInd:popInd,
   ln = '<a href="' + (href && type!='js:' ? href : '#') +
    '" onclick="return false" onfocus="this.blur()" class="' + tC +
    (isNS4 ? '" onmouseover="' + myName + '.over(\'' + mN + '\', ' + iN + ')"' : '"');

  // If we're supposed to add a popout indicator, add it before text so it appears below in NS4.
  if (popI && sm)
  {
   if (isNS4) itemStr += '<layer class="' + tC + '" left="'+ ((popPos+fW)%fW) +
    '" top="' + pad + '" height="' + (fH-2*pad) + '">' + popI + '</layer>';
   else itemStr += '<div class="' + tC + '" style="position: absolute; left: ' +
    ((popPos+fW)%fW) + 'px; top: ' + pad + 'px; height: ' + (fH-2*pad) + 'px">' + popI +
    '</div>';
  }

  // For NS4, if a border is assigned, add a spacer to push border out to layer edges.
  // Add a link both to generate an onclick event and to stop the ugly I-beam text cursor appearing.
  if (isNS4) itemStr += (outBorder ? '<span class="' + (isOver?overBorder:outBorder) +
   '"><spacer type="block" width="' + (fW-8) + '" height="' + (fH-8) + '"></span>' : '') +
   '<layer left="' + pad + '" top="' + pad + '" width="' + (fW-2*pad) + '" height="' +
   (fH-2*pad) + '">' + ln + '>' + txt + '</a></layer>';

  // IE4+/NS6 is an awful lot easier to work with sometimes.
  // I'm using a special case for IE4 though, which doesn't like positioning anchors, so I'm just
  // using a good old DIV tag instead.
  else
  {
   itemStr += (isIE4 ? '<div class="' + tC + '" ' : ln) + ' style="position: absolute; left: ' +
    pad + 'px; top: ' + pad + 'px; width: ' + (fW-2*pad) + 'px; height: ' + (fH-2*pad) +
    'px; cursor: ' + (href ? normCursor : nullCursor) + '">' + txt + (isIE4 ? '</div>' : '</a>');
  }
 }
 return itemStr;
}};


// The main menu creation/update routine. The first parameter is 'true' if you want the script
// to use document.write() to create the menus. Second parameter is optionally the name of one
// menu only to update rather then create all menus.
PmPt.update = function(docWrite, upMN) { with (this)
{
 // 'isDyn' (set at the very top of the script) signifies a DHTML-capable browser.
 if (!isDyn) return;

 // Loop through menus, using properties of menu description object (array index 0)...
 for (mN in menu) with (menu[mN][0])
 {
  // If we're updating one specific menu, only run the code for that.
  if (upMN && upMN!=mN) continue;

  // Variable for holding HTML for items, and parent frame for this menu (if any).
  var str = '', eP = eval(par);

  // When we are running in proper 'CSS1Compat' mode, borders affect widths differently, so we
  // set the 'dFix' (dimension fix) property of this menu based on its frame's DOCTYPE.
  // Yes, there is no standard way of detecting DOCTYPEs, this is as near as I can get ;).
  with (eP&&eP.navigator?eP:self) var dC = document.compatMode, dT = document.doctype;
  dFix = (dC&&dC.indexOf('CSS')>-1 || isOp&&!dC ||
          dT&&dT.name.indexOf('.dtd')>-1 || isDOM&&!isIE) ? 2 : 0;

  // Loop through all items in this menu array.
  // Remember, items start from 1 in the array (0 is menu object itself, above).
  // Also use properties of each item nested in the other with() for construction.
  for (var iN = 1; iN < menu[mN].length; iN++) with (menu[mN][iN])
  {
   // Now is a good time to assign another menu's parent to this if we've got a popout item.
   // Also get an ID for divs/layers contained within the menu.
   var tM = menu[sm], itemID = myName + '-' + mN + '-' + iN;
   if (sm && tM)
   {
    tM[0].parentMenu = mN;
    tM[0].parentItem = iN;
   }

   // Set the fW and fH properties of the item (fixed width and height) based on DOCTYPE.
   // That is, under strict DOCTYPEs we subtract 2px from each of the width and height to
   // accommodate for the box model changes, otherwise in loose mode we leave them the same.
   if (outBorder) { fW = iW - dFix; fH = iH - dFix }
   else { fW = iW; fH = iH }

   // Have we been given a background image? It'll have a period in its name if so...
   var isImg = (outCol.indexOf('.') != -1);

   // Create a div or layer text string with appropriate styles/properties.
   // OK, OK, I know this is a little obtuse in syntax, but it's small...
   // At the end we set the alpha transparency (if specified) and the mouse cursor.
   if (isDOM || isIE4)
   {
    str += '<div id="' + itemID + '" ' + (outBorder ? 'class="'+outBorder+'" ' : '') +
     'style="position: absolute; left: ' + iX + 'px; top: ' + iY + 'px; width: ' + fW +
     'px; height: ' + fH + 'px; z-index: ' + zIndex + '; ' +
     (outCol ? 'background: ' + (isImg?'url('+outCol+')':outCol) : '') +
     (typeof(outAlpha)=='number' ? '; filter: alpha(opacity=' + outAlpha + '); -moz-opacity: ' +
      outAlpha + '%; opacity: ' + (outAlpha/100): '') +
     '; cursor: ' + (href ? normCursor : nullCursor) + '" ';
   }
   else if (isNS4)
   {
    // NS4's borders must be assigned within the layer so they stay when content is replaced.
    str += '<layer id="' + itemID + '" left="' + iX + '" top="' + iY + '" width="' +
     fW + '" height="' + fH + '" z-index="' + zIndex + '" ' +
     (outCol ? (isImg ? 'background="' : 'bgcolor="') + outCol + '" ' : '');
   }

   // Add mouseover/out/click handlers, contents, and finish div/layer.
   // Note that we are careful to return the correct values from the over/click functions.
   var evtMN = "('" + mN + "'," + iN + ")";
   str += 'onmouseover="return ' + myName + '.over' + evtMN + '" onmouseout="' + myName + '.out' +
    evtMN + '" onclick="return ' + myName + '.click' + evtMN + '">' +  getHTML(mN, iN, 0) +
    (isNS4 ? '</layer>' : '</div>');

  // End loop through items and with(menu[mN][iN]).
  }



  // Do not ask me why Opera makes me set a timeout now rather than later, or in fact have
  // to set a timeout at all to get references to the divs we are about to create.
  // But, it makes the cross-frame version of the script actually work, so there's a benefit.
  var sR = myName + '.setupRef(' + (docWrite?1:0) + ', "' + mN + '")';
  if (isOp) setTimeout(sR, 1000);

  // Initial menu visibility -- normally hidden except for Opera bug workaround.
  var mVis = isOp&&isRoot ? 'visible' : 'hidden';

  // For Fast creation mode (default for IE, NS6+, Opera), write the menus to the document now.
  // I'm adding a bit to the widths for safety as borders are different across browsers.
  if (docWrite)
  {
   // Find the right target frame.
   var targFr = eP&&eP.navigator ? eP : window;
   // Write out a container div. Clipping seems to help NS6 with dropshadows.
   targFr.document.write('<div id="' + myName + '-' + mN + '" style="position: absolute; ' +
    'visibility: ' + mVis + '; left: ' + (isOp ? -1000 : 0) + '0px; top: 0px; width: ' +
    (menuW+2) + 'px; height: ' + (menuH+2) + 'px; z-index: 1000">' + str + extraHTML + '</div>');
  }
  else
  {
   // Create a new layer/div object dynamically using my setLyr() function above.
   // If we've got a layer created already, there's no use creating another!.
   // In IE4, we must shrink the menus to stop them sizing to the full body size -- thanks
   // to Jeff Blum and Paul Maden for debugging this for me :). If the layer has been created,
   // we've got to set a timeout to fix up IE4 again for some obscure reason.
   if (!lyr || !lyr.ref) lyr = setLyr(mVis, menuW, eP);
   else if (isIE4) setTimeout(myName + '.menu.' + mN + '[0].lyr.sty.width=' + (menuW+2), 50);

   // Give it a high Z-index, and write its content.
   with (lyr) { sty.zIndex = 1000; write(str + extraHTML) }
  }

  if (!isOp) setTimeout(sR, 100);

 // End loop through menus and with (menu[mN][0]).
 }
}};


// After the menu divs have been created, get references to them for later manipulation.
PmPt.setupRef = function(docWrite, mN) { with (this) with (menu[mN][0])
{
 var eP = eval(par);

 // Get a reference to a div, only needed for Fast creation mode.
 if (docWrite || !lyr || !lyr.ref) lyr = getLyr(myName + '-' + mN, eP);

 // Loop through menu items again to set up individual references.
 for (var i = 1; i < menu[mN].length; i++)
  menu[mN][i].lyr = getLyr(myName + '-' + mN + '-' + i, isNS4?lyr.ref:eP);

 // Setting clipping seems to help some early versions of NS6. Don't ask me why.
 lyr.clip(0, 0, menuW+2, menuH+2);

 // Call the 'oncreate' method of this menu if it exists (e.g. to show root menu).
 // Pass object reference, as within function 'this' will refer to the menu in question.
 if (oncreate) oncreate(this);
}};