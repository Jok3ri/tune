#include <atomic>
#include <string>

#include <util/Span.h>

namespace ecu
{

template <class TValue>
struct ChannelBounds
{
    ChannelBounds(TValue min, TValue max) : Min(min), Max(max) { }

    const TValue Min;
    const TValue Max;
};

struct OutputChannelBase
{
    OutputChannelBase(const std::string& displayName) : m_displayName(displayName) { }
    
    virtual float GetValueAsFloat() const = 0;
    virtual ChannelBounds<float> GetBoundsAsFloat() const = 0;
    
    // Update this channel using bytes read from the ECU, converting to the channel's native format
    virtual void PostBytes(Span<uint8_t> buffer) = 0;
    
    const std::string& GetDisplayName() const
    {
        return m_displayName;
    }
    
private:
    const std::string m_displayName;
};

template <class TValue>
class OutputChannel : public OutputChannelBase
{
public:
    OutputChannel(const std::string& id, const std::string& displayName, ChannelBounds<TValue> bounds)
        : OutputChannelBase(displayName)
        , Id(id)
        , Bounds(bounds)
    {
    }

    // OutputChannelBase implementation
    float GetValueAsFloat() const override
    {
        return GetValue();
    }

    ChannelBounds<float> GetBoundsAsFloat() const override
    {
        return ChannelBounds<float>(Bounds.Min, Bounds.Max);
    }
    
    void SetValue(TValue newValue)
    {
        m_value.store(newValue);
    }
    
    const TValue GetValue() const
    {
        return m_value.load();
    }

    const std::string Id;
    const ChannelBounds<TValue> Bounds;

private:
    std::atomic<TValue> m_value = 0;
};

class FloatOutputChannel final : public OutputChannel<float>
{
public:
    FloatOutputChannel(const std::string& id, const std::string& displayName, ChannelBounds<float> bounds)
        : OutputChannel(id, displayName, bounds)
    {
    }
    
    void PostBytes(Span<uint8_t> b)
    {
        uint32_t raw =
            (b[0] << 24) |
            (b[1] << 16) |
            (b[2] << 8) |
            (b[3] << 0);
        
        
        SetValue(*(float*)(&raw));
    }
};
}
