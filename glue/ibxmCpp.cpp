extern "C" {
#include "portable.h"
}
#include "ibxmCpp.h"

static struct data ibxm_data;
static struct module *ibxm_module = nullptr;
static struct replay *ibxm_replay = nullptr;
static char ibxm_message[64];

const char* ibxm_cpp_get_version() {
	return IBXM_VERSION;
}

int ibxm_cpp_load_module(unsigned char *file_data, int file_length) {
	ibxm_data.buffer = (char *)file_data;
	ibxm_data.length = file_length;
	ibxm_module = module_load(&ibxm_data, ibxm_message);
	return ibxm_module ? 0 : -1;
}

int ibxm_cpp_init(int sample_rate, int interpolation) {
	if (!ibxm_module) return -1;
	ibxm_replay = new_replay(ibxm_module, sample_rate, interpolation);
	loop = 1;
	if (ibxm_replay) {
		samples_remaining = replay_calculate_duration(ibxm_replay);
		return 0;
	}
	return -1;
}

const char* ibxm_cpp_get_name() {
	if (!ibxm_module) return "";
	return ibxm_module->name;
}

const char* ibxm_cpp_get_instrument(int instrument) {
	if (!ibxm_module) return "";
	if (instrument < 1 || instrument > ibxm_module->num_instruments) return "";
	return ibxm_module->instruments[instrument].name;
}

int ibxm_cpp_get_song_duration() {
	return samples_remaining;
}

void ibxm_cpp_get_audio(unsigned char *output_buffer, int len) {
	audio_callback(ibxm_replay, (short *)output_buffer, len);
}

void ibxm_cpp_set_position(int pos) {
	if (ibxm_replay) replay_set_sequence_pos(ibxm_replay, pos);
}

int ibxm_cpp_seek(int sample_pos) {
	if (!ibxm_replay) return 0;
	return replay_seek(ibxm_replay, sample_pos);
}

int ibxm_cpp_calculate_mix_buf_len(int sample_rate) {
	return calculate_mix_buf_len(sample_rate);
}

void ibxm_cpp_get_instrument_data(int index, unsigned char *output_buffer) {
	if (!ibxm_module) return;
	struct instrument *ins = &ibxm_module->instruments[index];
	memcpy(output_buffer, ins->name, 32);
	((int *)(output_buffer + 32))[0] = ins->num_samples;
	((int *)(output_buffer + 36))[0] = ins->vol_fadeout;
	((int *)(output_buffer + 40))[0] = ins->vib_type;
	((int *)(output_buffer + 44))[0] = ins->vib_sweep;
	((int *)(output_buffer + 48))[0] = ins->vib_depth;
	((int *)(output_buffer + 52))[0] = ins->vib_rate;
}

void ibxm_cpp_get_sample_data(int instrument, int sample, unsigned char *output_buffer) {
	if (!ibxm_module) return;
	struct sample *s = &ibxm_module->instruments[instrument].samples[sample];
	memcpy(output_buffer, s->name, 32);
	((int *)(output_buffer + 32))[0] = s->loop_start;
	((int *)(output_buffer + 36))[0] = s->loop_length;
	((int *)(output_buffer + 40))[0] = s->volume;
	((int *)(output_buffer + 44))[0] = s->panning == 0 ? -1 : s->panning - 1;
	((int *)(output_buffer + 48))[0] = s->rel_note;
	((int *)(output_buffer + 52))[0] = s->fine_tune;
}

void ibxm_cpp_set_muted(int channel, bool muted) {
	if (muted) {
		mute |= (1 << channel);
	} else {
		mute &= ~(1 << channel);
	}
}

bool ibxm_cpp_is_muted(int channel) {
	return (mute >> channel) & 1;
}

int ibxm_cpp_get_num_patterns() {
	if (!ibxm_module) return 0;
	return ibxm_module->num_patterns;
}

void ibxm_cpp_get_sequence(unsigned char *output_buffer) {
	if (!ibxm_module) return;
	int *out = (int *)output_buffer;
	for (int i = 0; i < ibxm_module->sequence_len; i++) {
		out[i] = ibxm_module->sequence[i];
	}
}

int ibxm_cpp_get_num_channels() {
	if (!ibxm_module) return 0;
	return ibxm_module->num_channels;
}

int ibxm_cpp_get_num_instruments() {
	if (!ibxm_module) return 0;
	return ibxm_module->num_instruments;
}

int ibxm_cpp_get_sequence_length() {
	if (!ibxm_module) return 0;
	return ibxm_module->sequence_len;
}

int ibxm_cpp_get_sequence_pos() {
	if (!ibxm_replay) return 0;
	return replay_get_sequence_pos(ibxm_replay);
}

int ibxm_cpp_get_row() {
	if (!ibxm_replay) return 0;
	return replay_get_row(ibxm_replay);
}

int ibxm_cpp_get_pattern_num_rows(int seq_pos) {
	if (!ibxm_module) return 0;
	int pat = ibxm_module->sequence[seq_pos];
	return ibxm_module->patterns[pat].num_rows;
}

void ibxm_cpp_get_pattern_data(int seq_pos, unsigned char *output_buffer) {
	if (!ibxm_module) return;
	int pat = ibxm_module->sequence[seq_pos];
	struct pattern *p = &ibxm_module->patterns[pat];
	memcpy(output_buffer, p->data, p->num_channels * p->num_rows * 5);
}
