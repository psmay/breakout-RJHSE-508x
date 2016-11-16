#!/bin/sh

EPS_NOOUTLINE="$1"
EPS_OUTLINEONLY="$2"
PNG_RESULT="$3"

WORK="`mktemp -d`" || exit 1

BGCOLOR="#4444FF"
DENSITY="600x600"

get_dimension () {
	case $1 in
		[lr])
			echo w
			;;
		[tb])
			echo h
			;;
	esac
}

get_opposite_gravity () {
	case $1 in
		l)
			echo east
			;;
		r)
			echo west
			;;
		t)
			echo south
			;;
		b)
			echo north
			;;
	esac
}

get_splice_dimensions () {
	case $1 in
		[lr])
			echo 1x0
			;;
		[tb])
			echo 0x1
			;;
	esac
}

trim_one_side () {
	side="$1"
	source_image="$2"
	destination_image="$3"

	gravity="`get_opposite_gravity "$side"`"
	sdim="`get_splice_dimensions "$side"`"

	convert "$source_image" \
		-gravity "$gravity" \
		-splice "$sdim" \
		-background black -splice "$sdim" \
		-trim +repage \
		-gravity "$gravity" \
		-chop "$sdim" \
		"$destination_image"
}

trim_then_measure_one_side () {
	side="$1"
	source_image="$2"

	dest_tmp_image="$WORK/trim_then_measure_one_side.tmp.png"
	dimension_name="`get_dimension "$side"`"

	trim_one_side "$side" "$source_image" "$dest_tmp_image"
	identify -format "%[$dimension_name]" "$dest_tmp_image"
	rm -rf "$dest_tmp_image"
}

crop_settings_from_outline_eps ()
{
	outline_eps="$1"
	# Get PNG copy of outline image
	grow_size=10
	outline_tmp_image="$WORK/outline.tmp.png"

	convert -density "$DENSITY" "$outline_eps" -background white "$outline_tmp_image"
	height_original="`identify -format '%[h]' "$outline_tmp_image"`"
	width_original="`identify -format '%[w]' "$outline_tmp_image"`"

	width_after_left_trim="`trim_then_measure_one_side 'l' "$outline_tmp_image"`"
	width_after_right_trim="`trim_then_measure_one_side 'r' "$outline_tmp_image"`"
	height_after_top_trim="`trim_then_measure_one_side 't' "$outline_tmp_image"`"
	height_after_bottom_trim="`trim_then_measure_one_side 'b' "$outline_tmp_image"`"

	rm -rf "$outline_tmp_image"

	trimmed_x0="`expr $width_original - $width_after_left_trim`"
	trimmed_x1="$width_after_right_trim"
	trimmed_y0="`expr $height_original - $height_after_top_trim`"
	trimmed_y1="$height_after_bottom_trim"

	grown_x0="`expr $trimmed_x0 - $grow_size`"
	grown_x1="`expr $trimmed_x1 + $grow_size`"
	grown_y0="`expr $trimmed_y0 - $grow_size`"
	grown_y1="`expr $trimmed_y1 + $grow_size`"

	grown_w="`expr $grown_x1 - $grown_x0`"
	grown_h="`expr $grown_y1 - $grown_y0`"

	echo "${grown_w}x${grown_h}+${grown_x0}+${grown_y0}"
}

compose_layout_images ()
{
	nooutline_eps="$1"
	outlineonly_eps="$2"
	output_png="$3"

	crop_settings="`crop_settings_from_outline_eps "$outlineonly_eps"`"

	convert \
		-background "$BGCOLOR" \
		-density "$DENSITY" "$nooutline_eps" -flatten \
		-density "$DENSITY" "$outlineonly_eps" -flatten \
		-crop "$crop_settings" +repage \
		$output_png
}

compose_layout_images "$EPS_NOOUTLINE" "$EPS_OUTLINEONLY" "$PNG_RESULT"

rm -rf "$WORK"
