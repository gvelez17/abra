// This file contains some useful additions to the menu script that don't appear in the
// standard script demo. You cut and paste these into the POP_DATA file. You'll find inside:
//
// 1) Custom mouse events, to set window status messages etc.
// 2) IE5.5+ filter animation function, for PowerPoint-like menu animations.
// 3) Custom item arrangement, for circular menus or multiple columns etc.
// 4) Select box / IFRAME / Applet / Flash hiding function, so select boxes don't overlap menus.
// 5) Long menu scrolling function, for menus larger than the window dimensions.
// 6) Menu navigation by keypresses.
// 7) Automatic site-map creator, for accessible websites.





// CUSTOM MOUSE EVENTS
//
// If you want, you can assign functions to handle menu mouse events like mouse over/out/click.
// 'with (this)' means use the properties of the menu object, and they're passed the current
// menu name (mN) and item number (iN) you can use to determine the source of the event.
// If any 'return false' you can cancel the action of the event (e.g. click or menu popout).
//
// To activate: Paste whichever of these events you need beneath your menu data.
// That means either in the POP_DATA file, or in your frameset file.

pMenu.onclick = function(mN, iN) { with (this)
{
 // Do actions depending on the item that the mouse was over at the time of the click.
 // You may with to use nested IFs or 'switch' statements etc. if you're familiar with JS.
 if (mN == 'root')
 {
  if (iN == 1) window.status = 'Congratulations, you\'ve mastered clicking!';
  if (iN == 2) location.href = 'edit.html';
  if (iN == 3) location.href = 'help.html';
  // For frameset navigation, use this syntax:
  //targetFrameName.location.href = 'blah.html';
 }
}};

// Set the status message to the URL if the 'action type' is nothing, and clear on mouseout.
// By now, you either have my 'JS Object Browser' script from my site or you need it... try
// embedding in an IFrame and typing 'pMenu' into its Go To field to see the menu internals.
pMenu.onmouseover = function(mN, iN) { with (this)
{
 with (menu[mN][iN]) if (type!='sm:' && type!='js:')
 {
  window.status = href;
  return true;
 }
}};

pMenu.onmouseout = function() { window.status = '' };






// IE5.5+/WINDOWS FILTER ANIMATION
//
// If you are doing this make sure that you either enable opacity in your ItemStyles, or
// disable it in the dropshadows, otherwise it looks weird.
//
// To activate: Insert menuFilterShow() into your POP_DATA or frameset script files, and replace
// the standard menu animation show/hide settings beneath the menu data with this:

pMenu.showMenu = function(mN)
{
 menuFilterShow(this, mN, 'progid:DXImageTransform.Microsoft.GradientWipe(' +
   'GradientSize=0.75,duration=0.5,wipestyle=1,motion=forward)') }
};

// By the way, there's a good list of transitions and documentation available from:
//  http://msdn.microsoft.com/workshop/author/filter/reference/reference.asp
// for a whole lot more PowerPoint-like effects you can use.

function menuFilterShow(menuObj, menuName, filterName)
{
 var mD = menuObj.menu[menuName][0];
 with (mD.lyr)
 {
  sty.filter = filterName;
  var f = ref.filters, doF = (f&&f.length&&f[0]);
  if (doF) f[0].Apply();
  vis('visible');
  if (doF) f[0].Play();
 }
};





// CUSTOM ITEM ARRANGEMENT
//
// To activate: Paste this into your menu data file, after your startMenu/addItem commands and
// before the border/dropshadow settings.
// Individual items have .iX and .iY which are positions and .iW and .iH which are dimensions.

with (pMenu.menu)
{
 // Extend overall menu pixel dimensions first.
 mFile[0].menuW += 20;
 mFile[0].menuH += 20;
 // Then adjust the item positions/dimensions.
 mFile[1].iX += 5;
 mFile[2].iX += 2;
 mFile[2].iW -= 2;
 mFile[3].iX += 5;
 mFile[4].iX += 10;
 mFile[4].iW += 10;
 mFile[4].iY += 3;
}


// Alternatively, here's a prebuild function that formats vertical menus into columns.
// To activate: paste it all beneath your menu data as above, then call pMenu.setColumns
// with the name of the menu you want to format, and the number of items you want per
// column in that menu. It looks best with dropshadows disabled too.

PopupMenu.prototype.setColumns = function(mN, numPerCol)
{
 var mnu = this.menu[mN], col = 0, num = 0, pos = 0;
 for (var i = 1; i < mnu.length; i++)
 {
  if (++num > numPerCol) { mnu[0].menuH = pos; pos = 0; num = 1; col++ }
  mnu[i].iX = col * (mnu[0].menuW - 1);
  mnu[i].iY = pos;
  pos += mnu[i].iH - 1;
 }
 mnu[0].menuW *= (col + 1);
};

pMenu.setColumns('mEdit', 5);









// SELECT BOX HIDING
//
// I have included two methods here for you to use; see which one suits you best...

// METHOD ONE: IE5.5+ SELECT BOX FIX
// This will allow the menus to display over SELECT boxes in IE5.5+ browsers.
// It will do nothing for NS4 or IE5.0 and earlier.
// To activate: paste this afte your menu data (either in the POP_DATA file, or your frameset)
// and then make sure you call IE55SelectBoxFix() for all your menu objects you want fixed.

function IE55SelectBoxFix(menuObj) { with (menuObj)
{
 if (window.createPopup) for (var mN in menu) with (menu[mN][0])
 {
  extraHTML += '<iframe src="about:blank" style="position: absolute; left: 0px; top: 0px; width: ' +
   menuW + 'px; height: ' + menuH + 'px; z-index: 0; border: none; ' +
   'filter: progid:DXImageTransform.Microsoft.Alpha(style=0,opacity=0)"></iframe>';
 }
}};
IE55SelectBoxFix(pMenu);


// METHOD TWO: DYNAMIC SHOW AND HIDE
// This can hide any element, like applets, movies and IFRAMEs, and it is more complicated :).
// To activate: Paste this into your menu data file (either POP_DATA or the frameset).
// This must be near the end of the file, after your menu animation settings in particular.
// It will automatically apply itself to all menus in that page.
// This function will have no effect on NS4's form behaviour.

PopupMenu.prototype.elementHide = function(mN, show)
{
 var hideTags = [];
 // <select> is hidden in all IE versions, and Opera < 7.0.
 if ((isIE && !isOp) || (isOp && !document.documentElement))
  hideTags[hideTags.length] = 'SELECT';
 // <iframe> is hidden in IE < 5.5, all Opera versions, and Mozilla < 1.0.
 if ((isIE && !isOp && !window.createPopup) || isOp ||
  navigator.userAgent.match('rv:0.')) hideTags[hideTags.length] = 'IFRAME';
 // <object> and <applet> are hidden in all browsers.
 hideTags[hideTags.length] = 'OBJECT';
 hideTags[hideTags.length] = 'APPLET';

 with (this.menu[mN][0])
 {
  if (!lyr || !lyr.ref) return;

  var oldFn = show ? 'ehShow' : 'ehHide';
  if (this[oldFn]) this[oldFn](mN);
  else this.menu[mN][0].lyr.vis(show ? 'visible' : 'hidden');
  if (!isDOM && !isIE) return;
  if (hideTags.length == -1) return;

  var w = par?eval(par):self;
  if (!w.hideElms) w.hideElms = [];
  var hE = w.hideElms;

  if (show)
  {
   var elms = [];
   for (var t = 0; t < hideTags.length; t++)
   {
    var tags = isDOM ? w.document.getElementsByTagName(hideTags[t]) :
     isIE ? w.document.all.tags(hideTags[t]) : null;
    for (var i = 0; i < tags.length; i++) elms[elms.length] = tags[i];
   }
   for (var eN = 0; eN < elms.length; eN++)
   {
    var eRef = elms[eN];
    with (w.page.elmPos(eRef)) var eX = x, eY = y;
    if (!(lyr.x()+menuW<eX || lyr.x()>eX+eRef.offsetWidth) &&
        !(lyr.y()+menuH<eY || lyr.y()>eY+eRef.offsetHeight))
    {
     if (!hE[eN]) hE[eN] = { ref: eRef, menus: [] };
     hE[eN].menus[mN] = true;
     eRef.style.visibility = 'hidden';
    }
   }
  }
  else for (var eN in hE)
  {
   var reShow = 1, eD = hE[eN];
   eD.menus[mN] = false;
   for (var eM in eD.menus) reShow &= !eD.menus[eM];
   if (reShow && eD.ref)
   {
    eD.ref.style.visibility = 'visible';
    delete hE[eN];
   }
  }
 }
 return;
}
for (var p in PopupMenu.list)
{
 var pm = PopupMenu.list[p];
 pm.ehShow = pm.showMenu;
 pm.showMenu = new Function('mN','this.elementHide(mN, true)');
 pm.ehHide = pm.hideMenu;
 pm.hideMenu = new Function('mN','this.elementHide(mN, false)');
}







// LONG MENU SCROLLING
//
// I've supplied two different versions of this code -- one for newer browsers that support the
// CSS2 'overflow' property (i.e. MSIE, Mozilla/NS6+, and recent Opera/Safari versions), and
// another below that is more generic. Pick and use one, not both!

// Overflow version: Paste this at the end of your menu data (either POP_DATA or your frameset).
// It will apply scrollbars to long vertical menus.
// For bonus points, you can remove the setInterval call and rewrite it to call checkMenuScroll()
// on menu show or window scroll/resize...

PopupMenu.prototype.checkMenuScroll = function() { with (this)
{
 for (var mN in litNow)
 {
  var mD = menu[mN][0], eP = eval(mD.par);
  if (!eP) eP = window;
  var pH = eP.page.winH(), pY = eP.page.scrollY();
  if (!(mD.counter % 100)) with (mD.lyr)
  {
   if (mD.menuH + y() >= pY + pH)
   {
    sty.clip = 'rect(0px auto auto 0px)';
    sty.width = (mD.menuW + 15) + 'px';
    sty.height = (pY + pH - y()) + 'px';
    sty.overflow = 'auto';
    ref.onmouseover = new Function('clearTimeout(' + myName + '.hideTimer)');
    ref.onmouseout = new Function(myName + '.out("' + mN + '", 0)');
   }
   else
   {
    sty.height = (mD.menuH + 2) + 'px';
    sty.overflow = 'visible';
   }
  }
 }
}};
for (var mObj in PopupMenu.list)
{
 if (!isNS4) setInterval(mObj + '.checkMenuScroll()', 500);
}


// Second, more generic version:
// This allows users to scroll menus larger than the current window area height by pointing
// at the top/bottom of the menu, and it will scroll up and down automatically.
// It may cause NS4 to crash more than normal when you have text-colour-changing enabled
// for your items; your experience may vary, but test in NS4 if it's important to you.
// If you want this extended with scrolling images or indicators, feel free to add it yourself,
// or perhaps hire me for the modification :).
//
// To activate: There's only two steps to installing this extension:

// STEP ONE: Paste this into the "EVENTS" JS file (at the end is a good spot for it):

var pmsMX = 0, pmsMY = 0, scrInt = null;
document.popOldMM = document.onmousemove;
if (isNS4) document.captureEvents(Event.MOUSEMOVE);
document.onmousemove = function(evt)
{
 evt = evt ? evt : window.event;
 pmsMY = isNS4 ? evt.pageY - page.scrollY() : evt.clientY;
 if (pmsMY < 20) popEvt('if(overI&&!scrInt){clearInterval(scrInt);' +
  'scrInt=setInterval(myName+".scrollMenu(\'"+overM+"\',-15)", 50)}', 0);
 else if (pmsMY > page.winH()-(scFr.isIE?20:35)) popEvt('if(overI&&!scrInt){clearInterval(scrInt);' +
  'scrInt=setInterval(myName+".scrollMenu(\'"+overM+"\',15)", 50)}', 0);
 else popEvt('if(scrInt){clearInterval(scrInt);scrInt=null}',0);
 return this.popOldMM ? this.popOldMM(evt) : (isNS4?this.routeEvent(evt):null);
};


// STEP TWO: Paste this at the end of your DATA file (or your CORE file, either works):
// For frameset use, this must be pasted at the end of your frameset file.

PopupMenu.prototype.scrollMenu = function(mN, amount) { with (this)
{
 var sm = menu[mN][0];
 if (sm.oldOffY+'' == 'undefined') sm.oldOffY = sm.offY;
 var eP = eval(sm.par||'self');
 if (sm.menuH < eP.page.winH())
 {
  sm.offY = sm.oldOffY;
  return position(mN);
 }
 sm.offY = (Math.min(0, Math.max(parseFloat(sm.lyr.y())-amount,
  eP.page.scrollY()+eP.page.winH()-sm.menuH))).toString();
 return position(mN);
}};






// NAVIGATION BY KEYPRESSES
//
// This allows users to navigate menus by pressing keys.
// You can navigate by the arrow keys, press [Enter] to navigate, and [Esc] to quit.
// It's not NS4 compatible, as NS4 doesn't allow arrow key detection, and it works best if all
// your menus are positioned relatively (i.e. their offsets are numbers, not strings).
// Opera also refuses to not scroll with arrowpresses, so I've put in a nasty hack there :).
//
// To activate: Paste the script below at the end of the POP_EVENTS file.
// Then, in your menu data file (either POP_DATA or your frameset), you must give each of your
// menu objects a 'focusKey' property so they respond to keypresses, along with optional other
// properties to set which other keys must be pressed at the time. You must pick a key combination
// that is not already used as a shortcut by the browser itself. For example, insert these lines
// below the startMenu and addItem commands to set CTRL+SHIFT+M as the activation key:
//pMenu.focusKey = 'm';
//pMenu.focusCtrl = true;
//pMenu.focusAlt = false;
//pMenu.focusShift = true;


window.keyMenu = null;
document.popKD = document.onkeydown;
document.onkeydown = function(evt)
{
 evt = evt||window.event;
 var key = evt.charCode||evt.keyCode, ret = true;

 var PML = scFr.PopupMenu.list;
 for (var pm in PML)
 {
  var fK = (PML[pm].focusKey||'').charCodeAt(0);
  if (evt.ctrlKey==PML[pm].focusCtrl && evt.altKey==PML[pm].focusAlt &&
   evt.shiftKey==PML[pm].focusShift && (key==fK || key+32==fK))
  {
   if (keyMenu == PML[pm]) key = 27;
   else keyMenu = PML[pm];
  }
 }

 if (keyMenu) with (keyMenu)
 {
  if (typeof keyMenu.keyScrY != 'number') keyMenu.keyScrY = page.scrollY();
  ret = false;

  if (!overM || !overI) over('root', 1);
  var dir = 0, mD = menu[overM][0], iD = menu[overM][overI];
  // Now, why does Opera return values >50,000 for arrow keys? :P
  // Anyway, we set the 'direction' based on the key presses and menu orientation.
  if (key == 38 || key == 57373) dir = mD.isVert ? -1 : -2;
  if (key == 40 || key == 57374) dir = mD.isVert ? 1 : 2;
  if (key == 37 || key == 57375) dir = mD.isVert ? -2 : -1;
  if (key == 39 || key == 57376) dir = mD.isVert ? 2 : 1;
  // Escape and Enter, two special keys.
  if (key == 13) click(overM, overI);
  if (key == 27) { over('', 0); keyMenu = null; return 1 }

  if (dir == 1 || dir == -1)
  {
   // Move the highlighted item up and down the current menu.
   overI += dir;
   if (overI >= menu[overM].length) overI -= menu[overM].length - 1;
   if (overI < 1)
   {
    // If we move back past the first item, return to the parent of non-root menus.
    if (!mD.isRoot) { overM = mD.parentMenu; overI = mD.parentItem }
    else overI += menu[overM].length - 1;
   }
   over(overM, overI);
  }
  else if (dir)
  {
   // Either shift to a submenu or go back to the parent menu.
   // For menus in the same frame I attempt to do some position detecting.
   if (iD.type == 'sm:')
   {
    var tM = menu[iD.sm][0];
    if ((tM.par != mD.par) || (dir*parseInt(tM['off'+(mD.isVert?'X':'Y')]) >= 0))
    {
     dir = 0;
     keyMenu.over(iD.sm, 1);
    }
   }
   if (dir && !mD.isRoot)
   {
    var pM = menu[mD.parentMenu];
    var nextItem = mD.parentItem + (mD.isVert != pM[0].isVert ? dir/2 : 0);
    nextItem = Math.max(1, Math.min(nextItem, pM.length-1));
    keyMenu.over(mD.parentMenu, nextItem);
   }
  }
 }

 return this.popKD ? this.popKD(evt)&&ret : ret;
};

document.popKP = document.onkeypress;
document.onkeypress = function(evt)
{
 if (keyMenu && scFr.isOp) setTimeout('scrollTo(page.scrollX(), '+keyMenu.keyScrY+')', 10);
 return this.popKP ? this.popKP(evt)&&!keyMenu : !keyMenu;
};







// AUTOMATIC SITE MAP CREATOR
//
// One of the downsides of JavaScript menus is that they're not search-engine or screenreader
// friendly. So here's a utility to convert a menu to a nicely formatted series of lists, to
// make maintaining a "site map" easy. Just cut and paste into the file containing your menu data.

// Usage: Just call the createSiteMapFrom method of your chosen menu object, optionally specifying
// a menu at which the map should begin.
setTimeout('pMenu.createSiteMapFrom("root")', 2000);

var csmWin = null, csmInd = '';
PopupMenu.prototype.recurseWrite = function(mN) { with (this)
{
 var d = csmWin.document;
 d.writeln(csmInd + '<ul>');
 csmInd += ' ';

 for (var iN = 1; iN < menu[mN].length; iN++)
 {
  d.write(csmInd + '<li>');
  var iD = menu[mN][iN];

  if (iD.href && iD.type != 'js:') d.write('<a href="' + iD.href + '">' + iD.text + '</a>');
  else d.write(iD.text);

  if (iD.sm)
  {
   csmInd += ' ';
   d.write('\n');
   this.recurseWrite(iD.sm);
   csmInd = csmInd.substring(1);
   d.write('\n' + csmInd);
  }

  d.writeln('</li>');
 }

 csmInd = csmInd.substring(1);
 d.write(csmInd + '</ul>');
}};
PopupMenu.prototype.createSiteMapFrom = function(mN) { with (this)
{
 csmWin = window.open('about:blank');
 if (!csmWin) return;
 csmWin.document.open('text/plain');
 this.recurseWrite(mN);
 csmWin.document.close();
}};
