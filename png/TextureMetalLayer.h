#import "Plane.h"

class TextureMetalLayer : public MetalLayer {
	
	private:
		
		id<MTLTexture> _texture;
		id<MTLBuffer> _texcoordBuffer;

		std::vector<id<MTLBuffer>> _argumentEncoderBuffer;

	public:
		
		id<MTLTexture> texture() { 
			return this->_texture; 
		}
		
		bool setup() {
			
			MTLTextureDescriptor *texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:this->_width height:this->_height mipmapped:NO];
			if(!texDesc) return false;
			
			this->_texture = [_device newTextureWithDescriptor:texDesc];
			if(!this->_texture) return false;
			
			if(MetalLayer::setup()==false) return false;
			
			this->_texcoordBuffer = [this->_device newBufferWithBytes:Plane::texcoord length:Plane::TEXCOORD_SIZE*sizeof(float)*2 options:MTLResourceOptionCPUCacheModeDefault];
			if(!this->_texcoordBuffer) return false;
			
			for(int k=0; k<this->_library.size(); k++) {
				this->_argumentEncoderBuffer.push_back([this->_device newBufferWithLength:sizeof(float)*[this->_argumentEncoder[k] encodedLength] options:MTLResourceOptionCPUCacheModeDefault]);

				[this->_argumentEncoder[k] setArgumentBuffer:this->_argumentEncoderBuffer[k] offset:0];
				[this->_argumentEncoder[k] setTexture:this->_texture atIndex:0];
			}
						
			return true;
		} 
		
		id<MTLCommandBuffer> setupCommandBuffer(long mode) {
						
			id<MTLCommandBuffer> commandBuffer = [this->_commandQueue commandBuffer];
			MTLRenderPassColorAttachmentDescriptor *colorAttachment = this->_renderPassDescriptor.colorAttachments[0];
			colorAttachment.texture = this->_metalDrawable.texture;
			colorAttachment.loadAction  = MTLLoadActionClear;
			colorAttachment.clearColor  = MTLClearColorMake(0.0f,0.0f,0.0f,0.0f);
			colorAttachment.storeAction = MTLStoreActionStore;
			
			id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:this->_renderPassDescriptor];
			[renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
			[renderEncoder setRenderPipelineState:this->_renderPipelineState[mode]];
			[renderEncoder setVertexBuffer:this->_verticesBuffer offset:0 atIndex:0];
			[renderEncoder setVertexBuffer:this->_texcoordBuffer offset:0 atIndex:1];
			
			[renderEncoder useResource:this->_texture usage:MTLResourceUsageSample];
			[renderEncoder setFragmentBuffer:this->_argumentEncoderBuffer[mode] offset:0 atIndex:0];
			
			[renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:Plane::INDICES_SIZE indexType:MTLIndexTypeUInt16 indexBuffer:this->_indicesBuffer indexBufferOffset:0];
			
			[renderEncoder endEncoding];
			[commandBuffer presentDrawable:this->_metalDrawable];
			this->_drawabletexture = this->_metalDrawable.texture;
			return commandBuffer;
		}
		
		TextureMetalLayer() {	
		}
		
		~TextureMetalLayer() {
		}
};
