#ifndef CUDA_CLASS_BERT
#define CUDA_CLASS_BERT

#include<string>
#include<vector>
#include "cuda_runtime.h"
#include <cublas_v2.h>

#include "common.h"

#include "../ops/layernorm.cuh"
#include "../ops/linear.cuh"
#include "../ops/embedding.cuh"
#include "../ops/batch_matmul.cuh"
#include "../ops/softmax.cuh"
#include "../utils/common.h"
#include "../ops/elementwise.cuh"
#include "../ops/op_kernel.cuh"
#include "../ops/crossEntropyLoss.cuh"

extern "C"
class bert {
    public:
        bert (bool BERT_Large=false, 
              int num_gpu = 0, 
              std::string dir = "",
              int max_batchsize = 0,
              int max_seq_length = 0);
        //TODO　Muti_GPU

        ~bert(){

            for(int i = 0; i < handle->num_hidden_layers; i++){
                delete attention_layernorm[i];
                delete output_layernorm[i];
                delete output_linear[i];
                delete intermediate_linear[i];
                delete batched_linear[i];
                delete attention_linear[i];
                delete query_key[i];
                delete prob_value[i];           
            }
            delete embedding;
            delete pooler_linear;
            // delete classify_linear;
            delete handle;
        }

        void init_ops();

        void copy_inputs(int* &words, 
                         int* &token_type,
                         int* &position, 
                         int* &attention_mask);

        void BERT_Inference (
                            int* words, 
                            int* token_types, 
                            size_t batchsize, 
                            size_t seq_length, 
                            int* attention_mask=nullptr);

        // float* classify_inference(size_t num_classes);
    
        // void classify_inference_backward(int *classes, size_t num_classes);

        void get_gpu_result(float* output,
                            float* gpu_tensor,
                            size_t total_size) {
            checkCudaErrors(cudaMemcpyAsync(output, 
                                            gpu_tensor, 
                                            sizeof(float)*total_size, 
                                            cudaMemcpyDeviceToHost,
                                            handle->cal_stream));
                
            cudaStreamSynchronize(handle->cal_stream);
        }

        global_handle* handle;

        Retval ret;

    private:
        std::vector<op_LayerNorm*> attention_layernorm;
        std::vector<op_LayerNorm*> output_layernorm;
        Embedding* embedding;
        std::vector<op_Linear*> output_linear;
        op_Linear* pooler_linear;
        // op_Linear* classify_linear;
        std::vector<op_Linear*> attention_linear;
        std::vector<op_Linear*> intermediate_linear;
        std::vector<op_BatchedLinear*> batched_linear;
        std::vector<op_SoftMax*> softmax;
        std::vector<op_Gelu*> gelu;
        std::vector<Query_Key*> query_key;
        std::vector<Prob_Value*> prob_value;
        op_Tanh* op_tanh;
        // op_SoftMax* classify_softmax;
        // op_CrossEntropyLoss* loss;

};

#endif
