
PROJECT=breakout-RJHSE-508x
SCHEMATIC_X=schematic
LAYOUT_X=layout
LAYOUT_TOP_X=$(LAYOUT_X)-top
LAYOUT_BOTTOM_X=$(LAYOUT_X)-bottom
BUILD=build
PDF_PRODUCTS = $(SCHEMATIC_X).pdf $(LAYOUT_X).pdf
PNG_PRODUCTS = $(SCHEMATIC_X).png $(LAYOUT_TOP_X).png $(LAYOUT_BOTTOM_X).png
DISPLAY_PRODUCTS = $(PNG_PRODUCTS)

default: $(DISPLAY_PRODUCTS)

$(BUILD):
	mkdir -p build

distclean: clean
	rm -vf $(DISPLAY_PRODUCTS)

clean:
	rm -rvf $(BUILD)
	rm -rvf $(PROJECT).pcb- $(PROJECT).sch~ $(PROJECT).net

$(SCHEMATIC_X).pdf: $(BUILD)/schematic.pdf
	cp $^ $@

$(LAYOUT_X).pdf: $(BUILD)/layout.pdf
	cp $^ $@

$(SCHEMATIC_X).png: $(BUILD)/schematic.png
	cp $^ $@

$(LAYOUT_TOP_X).png: $(BUILD)/layout-top.png
	cp $^ $@

$(LAYOUT_BOTTOM_X).png: $(BUILD)/layout-bottom.png
	cp $^ $@




$(BUILD)/schematic.pdf: $(PROJECT).sch | $(BUILD)
	gaf export -o $@ $^

$(BUILD)/schematic.png: $(BUILD)/schematic.pdf | $(BUILD)
	convert -density 200x200 $^ -scale 40% $@

$(BUILD)/layout.ps: $(PROJECT).pcb | $(BUILD)
	pcb -x ps --psfile $@ $^

$(BUILD)/layout.pdf: $(BUILD)/layout.ps | $(BUILD)
	ps2pdf $^ $@

$(BUILD)/layout-top-nooutline.eps: $(PROJECT).pcb | $(BUILD)
	pcb -x eps --layer-stack "top,silk" --layer-color-1 '#000088' --element-color '#FFFFFF' --as-shown --eps-file $@ $^

$(BUILD)/layout-top-outlineonly.eps: $(PROJECT).pcb | $(BUILD)
	pcb -x eps --layer-stack "outline" --layer-color-7 '#FF8800' --as-shown --eps-file $@ $^

$(BUILD)/layout-top.png: $(BUILD)/layout-top-nooutline.eps $(BUILD)/layout-top-outlineonly.eps | $(BUILD)
	./autosize-and-compose-layout.sh $^ $@

$(BUILD)/layout-bottom-nooutline.eps: $(PROJECT).pcb | $(BUILD)
	pcb -x eps --layer-stack "bottom,silk,solderside" --layer-color-2 '#000088' --element-color '#FFFFFF' --as-shown --eps-file $@ $^

$(BUILD)/layout-bottom-outlineonly.eps: $(PROJECT).pcb | $(BUILD)
	pcb -x eps --layer-stack "outline,solderside" --layer-color-7 '#FF8800' --as-shown --eps-file $@ $^

$(BUILD)/layout-bottom.png: $(BUILD)/layout-bottom-nooutline.eps $(BUILD)/layout-bottom-outlineonly.eps | $(BUILD)
	./autosize-and-compose-layout.sh $^ $@

# To produce gerber files, do
#
# 	make gerbv-drills
#
# which opens gerbv to merge the drill files
#
# 	File->Export->Excellon drill merge...
#
# to a single *.cnc file in the same dir.
#
# Then, do
#
# 	make gerbers
#
# The zipped gerbers will be in the build dir.

$(BUILD)/gerber-files: $(PROJECT).pcb | $(BUILD)
	rm -rf $@
	mkdir -p $@
	pcb -x gerber --gerberfile $@/$(PROJECT) $<
	for i in $@/*.cnc; do mv -v $$i $$i.UNMERGED; done

export-gerbers: $(BUILD)/gerber-files

gerbv-drills: export-gerbers
	gerbv $(BUILD)/gerber-files/*.cnc.UNMERGED

$(BUILD)/$(PROJECT)-gerbers.zip: $(BUILD)/gerber-files | $(BUILD)
	rm -rf $@
	zip -j $@ $</*.gbr $</*.cnc 

gerbers: $(BUILD)/$(PROJECT)-gerbers.zip


