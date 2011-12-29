Editor = require 'editor'
$ = require 'jquery'
ck = require 'coffeekup'
fs = require 'fs'

describe "Editor", ->
  mainDiv = null
  editor = null
  filePath = null
  tempFilePath = null

  beforeEach ->
    filePath = require.resolve 'fixtures/sample.txt'
    tempFilePath = '/tmp/temp.txt'
    spyOn(Editor.prototype.viewProperties, 'open').andCallThrough()
    editor = Editor.build()

  afterEach ->
    fs.remove tempFilePath
    editor.destroy()

  describe "initialize", ->
    it "opens the given url", ->
      Editor.build(url: tempFilePath)
      expect(Editor.prototype.viewProperties.open).toHaveBeenCalledWith(tempFilePath)

  describe 'destroy', ->
    it 'destroys the ace editor', ->
      spyOn(editor.aceEditor, 'destroy').andCallThrough()
      editor.destroy()
      expect(editor.aceEditor.destroy).toHaveBeenCalled()

  describe "open(url)", ->
    describe "when called with a url", ->
      it "loads a buffer for the given url into the editor", ->
        editor.open(filePath)
        fileContents = fs.read(filePath)
        expect(editor.getAceSession().getValue()).toBe fileContents
        expect(editor.buffer.url).toBe(filePath)
        expect(editor.buffer.getText()).toEqual fileContents

      it "sets the mode on the session based on the file extension", ->
        editor.open('something.js')
        expect(editor.getAceSession().getMode().name).toBe 'javascript'

        editor.open('something.text')
        expect(editor.getAceSession().getMode().name).toBe 'text'

      it "assigns the url on the $atomController global", ->
        editor.open("/other/path")
        expect($atomController.url.toString()).toEqual("/other/path")

    describe "when called with null", ->
      it "loads an empty buffer with no url", ->
        editor.open()
        expect(editor.getAceSession().getValue()).toBe ""
        expect(editor.buffer.url).toBeUndefined()
        expect(editor.buffer.getText()).toEqual ""

  describe "when the text is changed via the ace editor", ->
    it "updates the buffer text", ->
      editor.open(filePath)
      expect(editor.buffer.getText()).not.toMatch /^.ooo/
      editor.getAceSession().insert {row: 0, column: 1}, 'ooo'
      expect(editor.buffer.getText()).toMatch /^.ooo/

  describe "save", ->
    describe "when the current buffer has a url", ->
      beforeEach ->
        editor.open tempFilePath
        expect(editor.buffer.url).toBe tempFilePath

      it "saves the current buffer to disk", ->
        editor.buffer.setText 'Edited buffer!'
        expect(fs.exists(tempFilePath)).toBeFalsy()

        editor.save()

        expect(fs.exists(tempFilePath)).toBeTruthy()
        expect(fs.read(tempFilePath)).toBe 'Edited buffer!'

    describe "when the current buffer has no url", ->
      selectedFilePath = null
      beforeEach ->
        expect(editor.buffer.url).toBeUndefined()
        editor.buffer.setText 'Save me to a new url'
        spyOn(atom.native, 'savePanel').andCallFake -> selectedFilePath

      it "presents a 'save as' dialog", ->
        editor.save()
        expect(atom.native.savePanel).toHaveBeenCalled()

      describe "when a url is chosen", ->
        it "saves the buffer to the chosen url", ->
          selectedFilePath = '/tmp/temp.txt'

          editor.save()

          expect(fs.exists(selectedFilePath)).toBeTruthy()
          expect(fs.read(selectedFilePath)).toBe 'Save me to a new url'

      describe "when dialog is cancelled", ->
        it "does not save the buffer", ->
          selectedFilePath = null

          editor.save()

          expect(fs.exists(selectedFilePath)).toBeFalsy()

