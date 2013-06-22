// Frameset support. This finds the right window containing a PopupMenu object.
// Testing for list.length works around a crazy OmniWeb bug.
var scFr=(self.PopupMenu&&self.PopupMenu.list.length)?self:(parent.PopupMenu?parent:top);

// This runs functions for a list of PopupMenu objects.
// You pass it a string to evaluate in the context of a menu object (e.g. 'position()')
// and optionally a second parameter to eval that string for each menu in that object
// appearing in this frame (e.g. to position all frame menus on scroll etc.).
// You can use 'mN' which is the current menuName in eval'd strings for the page events.
function popEvt(str, each)
{
 // IE5.x/Mac cross-frame error check.
 if (!scFr || !scFr.PopupMenu) return;
 var PML=scFr.PopupMenu.list, mN;
 for (var obj in PML)
 {
  // Workaround Firefox 1.0.3+ bug to force the correct scope within the eval() statement.
  var evStr = 'var objName = "' + obj + '", PML = self.scFr.PopupMenu.list, pm = PML[objName];';
  if (each) for (mN in PML[obj].menu)
  {
   var mD = PML[obj].menu[mN][0];
   // Either: single frame menus, OR frameset menus with the menu appearing in this frame.
   if ((!mD.par && scFr == self) ||
    (mD.par && mD.par.substring(mD.par.lastIndexOf('.')+1) == self.name))
   {
    var doCmd = evStr + 'var mN = "' + mN + '"; ' + str;
    eval(doCmd);
    // NESTED FRAMES SUPPORT: Remove the above eval() line and uncomment this next line:
    //if ((PML[obj].menu.root[0].par==self.name) == (isRoot?true:false)) eval(doCmd);
   }
  }
  else { eval(evStr + str); }
 }
};

// Backup a whole load of page events, and get NS/Opera window sizes.
var scrFn, popOL=window.onload, popUL=window.onunload, popOR=window.onresize, popOS=window.onscroll,
 nsWinW=window.innerWidth, nsWinH=window.innerHeight, nsPX=window.pageXOffset, nsPY=window.pageYOffset;
document.popOC=document.onclick;



// Only run the rest if we've found the core menu script in this or a parent window!
if (scFr.PopupMenu)
{

// Import a local copy the 'page' object from the main menu window into this frame.
// I'm also grabbing 'isNS4' as it's used a lot here.
if (!self.page) var isNS4=scFr.isNS4, page={};
if (scFr != self) for (var f in scFr.page) page[f]=scFr.page[f];
page.win = self;

// Import the menu names into this window, i.e. create self.pMenu = parent.pMenu;
popEvt('self[objName]=pm', 0);

// Most functions here will set a page event, and run one of the backed up functions in the
// list above once the event fires (so when you mix this with other scripts, they work too).
// If you're really tweaking for speed, feel free to remove the backup code.


// Menu creation: We select creation modes on a per-browser basis, using the update() function.
// In non-NS4 browsers, we document.write() a menu by calling update(true,...);
// In NS4, we have to create menus dynamically on page load completion using update(false,...);
// Other browsers like MSIE, NS6+, Op7+ also support dynamic creation mode, use it if you want.
// Dynamic mode is independent of script postion in the document (i.e. it can be in the HEAD).
// We also run our scrFn scroll-detector every 50ms in NS4, and set an onunload to clear menus.
if (!isNS4) popEvt('pm.update(true,mN)',1);
window.onload=function()
{
 if (popOL) popOL();
 // DYNAMIC MENU CREATION SUPPORT: To enable, *remove* the above "popEvt('update(...)')" line,
 // and *replace* the next popEvt('update(...)') line with this:
 //popEvt('if(isRoot)update(false,mN)',1); if(isNS4)setInterval(scrFn,50);
 if (isNS4) { popEvt('pm.update(false,mN)',1); setInterval(scrFn,50) }
 // This next function is mostly a random IE6 fix, but freeing ref's is generally a good thing.
 // Don't cleanup for Opera, which cheats a LOT on its back/forward navigation.
 if (!scFr.isOp) window.onunload=new Function(
  'if(popUL)popUL();popEvt("for(var i=0;i<pm.menu[mN].length;i++)pm.menu[mN][i].lyr=null",1)');
};



// WINDOW SCROLLING: In IE and some Moz versions self.onscroll works, so we capture that to
// call position(). In other browsers we have to create an interval to sniff the scroll position.
if (popOS||(''+popOS!='undefined'))
window.onscroll=function()
{
 if (popOS) popOS();
 popEvt('pm.position(mN)',1);
};
else
{
 scrFn='if (nsPX!=pageXOffset || nsPY!=pageYOffset)' +
  '{nsPX=pageXOffset;nsPY=pageYOffset;popEvt("pm.position(mN)",1)}';
 if (!isNS4) setInterval(scrFn,50);
}

// WINDOW RESIZE: NS4 and Opera 5/6 do horrible things on resize, so we check the window
// dimensions and reload this page/frame on window resize. Other browsers: call position().
// Opera 5/6 require a setInterval as they (stupidly!) don't support self.onresize().
function resizeBugCheck(){ if (nsWinW!=innerWidth || nsWinH!=innerHeight) location.reload() };
if (scFr.isOp&&!document.documentElement&&!self.opFix)
 self.opFix=setInterval('resizeBugCheck()',500);
window.onresize=function()
{
 if (popOR) popOR();
 if (isNS4) resizeBugCheck();
 popEvt('pm.position(mN)',1);
};

// DOCUMENT CLICKING: Find which menu has been clicked for NS4, and hide menus if set.
// Also hide all menus if that preference is set, and return 'undefined' to allow other event
// handlers to return true or false themselves.
if (isNS4) document.captureEvents(Event.CLICK);
document.onclick=function(evt)
{
 popEvt('if (isNS4&&pm.overI) pm.click(pm.overM, pm.overI);' +
  'if (!pm.overI&&pm.hideDocClick) pm.over("root", 0)',0);
 return document.popOC ? document.popOC(evt) : (isNS4 ? document.routeEvent(evt) : self.uNdEfInEd);
};


// End of 'if (scFr.PopupMenu)'
}