/* Global array to cache id's */
loginFormToggleLinks = [];

/* Focus to first form field */
function loginFocus(form) {
  form.find('input[type=text], input[type=email]').filter(':visible:first').focus();
}

/* Show single login element */
function loginShow(focused) {
  /* funktion generator rememberes the elem variable */
  var show = function(link) { return function() { link.slideDown('fast'); }; };

  /* Single form */
  if (loginFormToggleLinks.length == 1) {
    var link = $(loginFormToggleLinks[0]);
    var form = $('#' + link.data('form'));
    form.slideToggle('slow');
  }
  /* Handle multiple forms */
  else if (loginFormToggleLinks.length > 1) {
    for (var i = 0; i < loginFormToggleLinks.length; i++) {
      var elem = loginFormToggleLinks[i];
      var link = $(elem);
      var form = $('#' + link.data('form'));
      var hide = (elem != focused);
      var visible = form.is(':visible');
      if (hide && visible) {
        form.slideUp('slow', show(link));
      } else if (!hide && !visible) {
        link.slideUp('fast');
        form.slideDown('slow');
        loginFocus(form);
      }
    }
  }
}

/* initialize login page */
function loginPage(initial) {
  /* search all form toggling links */
  $('a.login-toggle').each(function(i, e) {
      $(e).click(function(event) {
        event.preventDefault();
        loginShow(this);
      });
      loginFormToggleLinks.push(e);
  });

  /* hide a single form */
  if (loginFormToggleLinks.length == 1) {
    var link = $(loginFormToggleLinks[0]);
    var form = $('#' + link.data('form'));
    form.hide();
    link.show();
    /* focus initial form */
    loginFocus($('#' + initial));
  }
  /* hide all except initial form */
  else if (loginFormToggleLinks.length > 1) {
    for (var i = 0; i < loginFormToggleLinks.length; i++) {
      var link = $(loginFormToggleLinks[i]);
      var form_id = link.data('form');
      var form = $('#' + form_id);
      if (form_id != initial) {
        form.hide();
        link.show();
      } else {
        /* focus initial form */
        loginFocus(form);
      }
    }
  }
}
