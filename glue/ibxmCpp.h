#pragma once

const char* ibxm_cpp_get_version();
int ibxm_cpp_load_module(unsigned char *file_data, int file_length);
int ibxm_cpp_init(int sample_rate, int interpolation);
const char* ibxm_cpp_get_name();
const char* ibxm_cpp_get_instrument(int instrument);
int ibxm_cpp_get_song_duration();
void ibxm_cpp_get_audio(unsigned char *output_buffer, int len);
void ibxm_cpp_set_position(int pos);
int ibxm_cpp_seek(int sample_pos);
int ibxm_cpp_calculate_mix_buf_len(int sample_rate);
void ibxm_cpp_set_muted(int channel, bool muted);
bool ibxm_cpp_is_muted(int channel);
int ibxm_cpp_get_num_patterns();
void ibxm_cpp_get_sequence(unsigned char *output_buffer);
void ibxm_cpp_get_instrument_data(int index, unsigned char *output_buffer);
void ibxm_cpp_get_sample_data(int instrument, int sample, unsigned char *output_buffer);
int ibxm_cpp_get_num_channels();
int ibxm_cpp_get_num_instruments();
int ibxm_cpp_get_sequence_length();
int ibxm_cpp_get_sequence_pos();
int ibxm_cpp_get_row();
int ibxm_cpp_get_pattern_num_rows(int seq_pos);
void ibxm_cpp_get_pattern_data(int seq_pos, unsigned char *output_buffer);
