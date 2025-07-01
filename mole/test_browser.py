import asyncio
import os
from browser_use import Agent, BrowserSession
from dotenv import load_dotenv

load_dotenv()

async def test_browser():
    print("Testing browser session...")
    
    try:
        # Simple browser session
        browser_session = BrowserSession(
            headless=False,
            args=["--window-size=800,600"]
        )
        
        print("Creating agent...")
        from browser_use.llm import ChatAnthropic
        
        llm = ChatAnthropic(
            model="claude-3-5-sonnet-20241022",
            api_key=os.getenv('ANTHROPIC_API_KEY')
        )
        
        agent = Agent(
            task="Navigate to google.com and take a screenshot",
            llm=llm,
            browser_session=browser_session
        )
        
        print("Running agent...")
        result = await agent.run()
        
        print(f"Result: {result}")
        print(f"Final result: {result.final_result() if hasattr(result, 'final_result') else 'No final_result method'}")
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_browser())
