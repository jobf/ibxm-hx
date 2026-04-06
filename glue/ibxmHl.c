
#define HL_NAME(n) ibxmHl_##n

#include "ibxm.h"
#include "portable.h"
#include <hl.h>

struct data data;
struct module *module;
struct replay *replay;
char message[64] = "";

// get_version

HL_PRIM vbyte *HL_NAME(get_version)(_NO_ARG) {
	const uchar *utext = (uchar *)IBXM_VERSION;

	hl_buffer *b = hl_alloc_buffer();
	hl_buffer_str(b, utext);
	vbyte *string = (vbyte *)hl_buffer_content(b, NULL);

	return string;
}

DEFINE_PRIM(_BYTES, get_version, _NO_ARG);

// calculate_mix_buf_len

HL_PRIM int HL_NAME(calculate_mix_buf_len)(int sample_rate) {
	const int mix_buf_len = calculate_mix_buf_len(sample_rate);
	return mix_buf_len;
}

DEFINE_PRIM(_I32, calculate_mix_buf_len, _I32);

// initialise

HL_PRIM int HL_NAME(initialise)(vbyte *file_data, int file_length,
																int sample_rate, int interpolation) {

	char *cfile_data = (char *)file_data;
	data.buffer = cfile_data;
	data.length = file_length;
	module = module_load(&data, message);
	if (!module) return -1;
	replay = new_replay(module, sample_rate, interpolation);
	loop = 1;
	if (replay) return 0;
	return -1;
}

DEFINE_PRIM(_I32, initialise, _BYTES _I32 _I32 _I32);

// get_instrument

HL_PRIM vbyte *HL_NAME(get_instrument)(int instrument) {

	const uchar *utext = (uchar *)module->instruments[instrument].name;

	hl_buffer *b = hl_alloc_buffer();
	hl_buffer_str(b, utext);
	vbyte *string = (vbyte *)hl_buffer_content(b, NULL);

	return string;
}

DEFINE_PRIM(_BYTES, get_instrument, _I32);

// calculate_song_duration

HL_PRIM int HL_NAME(calculate_song_duration)(_NO_ARG) {
	samples_remaining = replay_calculate_duration(replay);
	return samples_remaining;
}

DEFINE_PRIM(_I32, calculate_song_duration, _NO_ARG);

// get_audio

HL_PRIM void HL_NAME(get_audio)(vbyte *output_buffer, int len) {
	audio_callback(replay, (short *)output_buffer, len);
}

DEFINE_PRIM(_VOID, get_audio, _BYTES _I32);

// set_position

HL_PRIM void HL_NAME(set_position)(int pos) {
	replay_set_sequence_pos(replay, pos);
}

DEFINE_PRIM(_VOID, set_position, _I32);

// seek

HL_PRIM int HL_NAME(seek)(int sample_pos) {
	return replay_seek(replay, sample_pos);
}

DEFINE_PRIM(_I32, seek, _I32);

// get_name

HL_PRIM vbyte *HL_NAME(get_name)(_NO_ARG) {
	const uchar *utext = (uchar *)module->name;

	hl_buffer *b = hl_alloc_buffer();
	hl_buffer_str(b, utext);
	vbyte *string = (vbyte *)hl_buffer_content(b, NULL);

	return string;
}

DEFINE_PRIM(_BYTES, get_name, _NO_ARG);

// get_instrument_data

HL_PRIM void HL_NAME(get_instrument_data)(int index, vbyte *output_buffer) {
	struct instrument *ins = &module->instruments[index];
	memcpy(output_buffer, ins->name, 32);
	((int *)(output_buffer + 32))[0] = ins->num_samples;
	((int *)(output_buffer + 36))[0] = ins->vol_fadeout;
	((int *)(output_buffer + 40))[0] = ins->vib_type;
	((int *)(output_buffer + 44))[0] = ins->vib_sweep;
	((int *)(output_buffer + 48))[0] = ins->vib_depth;
	((int *)(output_buffer + 52))[0] = ins->vib_rate;
}

DEFINE_PRIM(_VOID, get_instrument_data, _I32 _BYTES);

// get_sample_data

HL_PRIM void HL_NAME(get_sample_data)(int instrument, int sample,
																			vbyte *output_buffer) {
	struct sample *s = &module->instruments[instrument].samples[sample];
	memcpy(output_buffer, s->name, 32);
	((int *)(output_buffer + 32))[0] = s->loop_start;
	((int *)(output_buffer + 36))[0] = s->loop_length;
	((int *)(output_buffer + 40))[0] = s->volume;
	((int *)(output_buffer + 44))[0] = s->panning == 0 ? -1 : s->panning - 1;
	((int *)(output_buffer + 48))[0] = s->rel_note;
	((int *)(output_buffer + 52))[0] = s->fine_tune;
}

DEFINE_PRIM(_VOID, get_sample_data, _I32 _I32 _BYTES);

// set_muted

HL_PRIM void HL_NAME(set_muted)(int channel, bool muted) {
	if (muted) {
		mute |= (1 << channel);
	} else {
		mute &= ~(1 << channel);
	}
}

DEFINE_PRIM(_VOID, set_muted, _I32 _BOOL);

// is_muted

HL_PRIM bool HL_NAME(is_muted)(int channel) { return (mute >> channel) & 1; }

DEFINE_PRIM(_BOOL, is_muted, _I32);

// get_num_patterns

HL_PRIM int HL_NAME(get_num_patterns)(_NO_ARG) { return module->num_patterns; }

DEFINE_PRIM(_I32, get_num_patterns, _NO_ARG);

// get_sequence

HL_PRIM void HL_NAME(get_sequence)(vbyte *output_buffer) {
	int i;
	int *out = (int *)output_buffer;
	for (i = 0; i < module->sequence_len; i++) {
		out[i] = module->sequence[i];
	}
}

DEFINE_PRIM(_VOID, get_sequence, _BYTES);

// get_num_channels

HL_PRIM int HL_NAME(get_num_channels)(_NO_ARG) { return module->num_channels; }

DEFINE_PRIM(_I32, get_num_channels, _NO_ARG);

// get_num_instruments

HL_PRIM int HL_NAME(get_num_instruments)(_NO_ARG) {
	return module->num_instruments;
}

DEFINE_PRIM(_I32, get_num_instruments, _NO_ARG);

// get_sequence_length

HL_PRIM int HL_NAME(get_sequence_length)(_NO_ARG) {
	return module->sequence_len;
}

DEFINE_PRIM(_I32, get_sequence_length, _NO_ARG);

// get_sequence_pos

HL_PRIM int HL_NAME(get_sequence_pos)(_NO_ARG) {
	return replay_get_sequence_pos(replay);
}

DEFINE_PRIM(_I32, get_sequence_pos, _NO_ARG);

// get_row

HL_PRIM int HL_NAME(get_row)(_NO_ARG) { return replay_get_row(replay); }

DEFINE_PRIM(_I32, get_row, _NO_ARG);

// get_pattern_num_rows

HL_PRIM int HL_NAME(get_pattern_num_rows)(int seq_pos) {
	int pat = module->sequence[seq_pos];
	return module->patterns[pat].num_rows;
}

DEFINE_PRIM(_I32, get_pattern_num_rows, _I32);

// get_pattern_data — copies num_channels * num_rows * 5 bytes into
// output_buffer

HL_PRIM void HL_NAME(get_pattern_data)(int seq_pos, vbyte *output_buffer) {
	int pat = module->sequence[seq_pos];
	struct pattern *p = &module->patterns[pat];
	memcpy(output_buffer, p->data, p->num_channels * p->num_rows * 5);
}

DEFINE_PRIM(_VOID, get_pattern_data, _I32 _BYTES);