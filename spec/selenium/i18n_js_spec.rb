require File.expand_path(File.dirname(__FILE__) + "/common")

describe "i18n js" do
  include_context "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    get "/"
    if CANVAS_WEBPACK
      # I18n will already be exposed in webpack land
    else
      # get I18n and _ global for all the tests
      driver.execute_script "require(['i18nObj', 'underscore'], function (I18n, _) { window.I18n = I18n; window._ = _; });"
    end
  end

  context "strftime" do
    it "should format just like ruby" do
      # everything except %N %6N %9N %U %V %W %Z
      format = "%a %A %b %B %d %-d %D %e %F %h %H %I %j %k %l %L %m %M %n %3N %p %P %r %R %s %S %t %T %u %v %w %y %Y %z %%"
      date = Time.now
      expect(driver.execute_script(<<-JS).upcase).to eq date.strftime(format).upcase
        var date = new Date(#{date.strftime('%s')} * 1000 + #{date.strftime('%L').gsub(/^0+/, '')});
        return I18n.strftime(date, '#{format}');
      JS
    end
  end

  context "locales" do
    it "should pull in core translations for all locales" do
      skip('USE_OPTIMIZED_JS=true') unless ENV['USE_OPTIMIZED_JS']
      keep_trying_until do
        expect(driver.execute_script(<<-JS).sort).to eq I18n.available_locales.map(&:to_s).sort
        var ary = [];
        for (var locale in I18n.translations) {
          if (I18n.translations.hasOwnProperty(locale)) {
            var localeSet = I18n.translations[locale];
            var hasItAll = true;
            ['date', 'time', 'number', 'datetime', 'support'].forEach(function(key){
              if(hasItAll){
                hasItAll = localeSet[key] !== undefined && localeSet[key] !== null;
              }
            });
            if(hasItAll){
              ary.push(locale);
            }
          }
        }
        return ary;
        JS
      end
    end
  end

  context "scoped" do
    it "should use the scoped translations" do
      skip('USE_OPTIMIZED_JS=true') unless ENV['USE_OPTIMIZED_JS']
      skip('RAILS_LOAD_ALL_LOCALES=true') unless ENV['RAILS_LOAD_ALL_LOCALES']
      (I18n.available_locales - [:en]).each do |locale|
        exec_cs("I18n.locale = '#{locale}'")
        rb_value = I18n.t('dashboard.confirm.close', locale: locale)
        js_value = if CANVAS_WEBPACK
          driver.execute_script("return I18n.scoped('dashboard').t('confirm.close');")
        else
          require_exec('i18n!dashboard', "i18n.t('confirm.close')")
        end
        expect(js_value).to eq(rb_value)
      end
    end
  end
end
