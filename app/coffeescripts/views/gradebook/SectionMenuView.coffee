define [
  'i18n!gradebook2'
  'jquery'
  'underscore'
  'Backbone'
  'jst/gradebook2/section_to_show_menu'
  'compiled/jquery.kylemenu'
  'vendor/jquery.ba-tinypubsub'
  'jsx/gradebook/grid/actions/sectionsActions'
], (I18n, $, _, {View}, template, SectionsActions) ->

  class SectionMenuView extends View

    @optionProperty 'sections'
    @optionProperty 'course'
    @optionProperty 'showSections'

    @optionProperty 'currentSection'

    template: template

    determineDefaultSection: ->
      if @showSections || !@course
        defaultSection = I18n.t('all_sections', 'All Sections')
      else
        defaultSection = @course.name
      defaultSection

    constructor: (options) ->
      super
      @defaultSection = @determineDefaultSection()
      if @sections.length > 1
        @sections.unshift(name: @defaultSection, checked: !options.currentSection)
      @updateSections()

    render: ->
      @detachEvents()
      super
      @$('button').kyleMenu()
      @attachEvents()

    detachEvents: ->
      $.unsubscribe('currentSection/change', @onSectionChange)
      @$('.section-select-menu').off('menuselect')

    attachEvents: ->
      $.subscribe('currentSection/change', @onSectionChange)
      @$('.section-select-menu').on('click', (e) -> e.preventDefault())
      @$('.section-select-menu').on('menuselect', (event, ui) =>
        section = @$('[aria-checked=true] input[name=section_to_show_radio]').val() || undefined
        $.publish('currentSection/change', [section, @cid])
        @trigger('menuselect', event, ui, @currentSection)
      )

    onSectionChange: (section, author) =>
      @currentSection = section
      @updateSections()
      @render()

    updateSections: ->
      _.map(@sections, (section) =>
        section.checked = section.id == @currentSection
        section
      )

    showSections: ->
      @showSections

    toJSON: ->
      {
        sections: @sections,
        showSections: @showSections,
        currentSection: _.findWhere(@sections, id: @currentSection)?.name or @defaultSection
      }
